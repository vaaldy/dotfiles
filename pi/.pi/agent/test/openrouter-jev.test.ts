/**
 * Tests for the OpenRouter Jev image support: the documented Decisions image shape, local
 * validation, byte guards and tool registration. No network and no credentials are used.
 */
import assert from "node:assert/strict";
import { registerHooks } from "node:module";
import { test } from "node:test";

// Pi supplies these at runtime; map them to a stub before importing the extension.
const HOST_PACKAGES = [
  "@earendil-works/pi-coding-agent",
  "@earendil-works/pi-ai",
  "@earendil-works/pi-tui",
  "typebox",
];
registerHooks({
  resolve(specifier, context, next) {
    if (HOST_PACKAGES.includes(specifier)) {
      return { url: new URL("./pi-host-stub.mjs", import.meta.url).href, shortCircuit: true };
    }
    return next(specifier, context);
  },
});

const { DEFAULT_MODEL, TEXT_REQUEST_LIMIT, IMAGE_REQUEST_LIMIT, buildRequest, validateImages, evaluate } =
  await import("../extensions/openrouter-jev.ts");

const pngPart = (payload = "fake-png-bytes") => ({
  type: "image_url",
  image_url: { url: `data:image/png;base64,${Buffer.from(payload).toString("base64")}` },
});
const question = { type: "noul", instructions: "Is the subject present in the region?" };

test("text-only request keeps the default model and the old shape", () => {
  const { body, images } = buildRequest(DEFAULT_MODEL, "plain state", { present: question });
  const parsed = JSON.parse(body);
  assert.equal(images, 0);
  assert.equal(parsed.model, "typesafe/jev-1.13");
  assert.equal(parsed.state, "plain state");
  assert.equal(parsed.questions.present.type, "noul");
});

test("a model override is forwarded unchanged", () => {
  const { body } = buildRequest("typesafe/jev-1.14", "state", { present: question });
  assert.equal(JSON.parse(body).model, "typesafe/jev-1.14");
});

test("one image part in state is accepted and counted", () => {
  const state = ["Image `frame` shows one sprite.", pngPart()];
  const { body, images } = buildRequest(DEFAULT_MODEL, state, { present: question });
  assert.equal(images, 1);
  assert.ok(JSON.parse(body).state[1].image_url.url.startsWith("data:image/png;base64,"));
});

test("image parts are found at any depth in state", () => {
  const state = { frames: [{ frame: pngPart("a") }, { frame: pngPart("b") }] };
  assert.deepEqual(validateImages(state).images, 2);
  assert.equal(buildRequest(DEFAULT_MODEL, state, { present: question }).images, 2);
});

test("remote image URLs are rejected with guidance", () => {
  const state = ["see", { type: "image_url", image_url: { url: "https://example.com/a.png" } }];
  assert.throws(() => validateImages(state), /does not fetch remote http\(s\) URLs/);
});

test("non-PNG/JPEG formats are rejected", () => {
  const webp = { type: "image_url", image_url: { url: "data:image/webp;base64,AAAA" } };
  assert.throws(() => validateImages([webp]), /accepts image\/png and image\/jpeg only/);
});

test("text parts must be plain strings", () => {
  assert.throws(() => validateImages([{ type: "text", text: "hi" }]), /plain strings/);
});

test("malformed image parts are rejected", () => {
  assert.throws(() => validateImages([{ type: "image_url", image_url: {} }]), /image parts need/);
  assert.throws(() => validateImages([{ type: "image_url" }]), /image parts need/);
});

test("a data URL inside a plain string stays text, not an image part", () => {
  const { images } = validateImages(["is it here data:image/png;base64,AAAA"]);
  assert.equal(images, 0);
});

test("image parts in instructions or criteria are refused with guidance", () => {
  const questions = {
    present: { type: "noul", instructions: [pngPart()] },
  };
  assert.throws(
    () => buildRequest(DEFAULT_MODEL, "state", questions as never),
    /put images in state/
  );
  const criteria = { present: { type: "choice", instructions: "which?", criteria: { a: pngPart(), b: "other" } } };
  assert.throws(
    () => buildRequest(DEFAULT_MODEL, "state", criteria as never),
    /put images in state/
  );
});

test("text-only payloads keep the 64 KB guard", () => {
  assert.throws(
    () => buildRequest(DEFAULT_MODEL, "x".repeat(TEXT_REQUEST_LIMIT + 1), { present: question }),
    /exceeds 64000 bytes/
  );
});

test("image payloads get the larger guard and report their size", () => {
  const large = ["x".repeat(TEXT_REQUEST_LIMIT + 1), pngPart()];
  assert.equal(buildRequest(DEFAULT_MODEL, large, { present: question }).images, 1);
  assert.throws(
    () => buildRequest(DEFAULT_MODEL, ["x".repeat(IMAGE_REQUEST_LIMIT), pngPart()], { present: question }),
    /exceeds 4000000 bytes with 1 image/
  );
});

test("validation runs before credentials are consulted", async () => {
  const state = ["see", { type: "image_url", image_url: { url: "http://example.com/a.png" } }];
  await assert.rejects(
    () => evaluate({} as never, state, { present: question }),
    /does not fetch remote http\(s\) URLs/
  );
});

test("registration exposes the three tools and the model parameter", async () => {
  const mod = await import("../extensions/openrouter-jev.ts");
  const registered: any[] = [];
  const commands: any[] = [];
  const fakePi = {
    registerTool: (definition: any) => registered.push(definition),
    registerCommand: (name: string, definition: any) => commands.push({ name, definition }),
    on: () => {},
  };
  mod.default(fakePi as never);
  const names = registered.map((tool) => tool.name).sort();
  assert.deepEqual(names, ["or_jev_evaluate", "or_jev_find_skill", "or_jev_find_tools"]);
  assert.deepEqual(commands.map((command) => command.name), ["or-jev"]);
  const evaluateTool = registered.find((tool) => tool.name === "or_jev_evaluate");
  assert.equal(typeof evaluateTool.execute, "function");
  assert.match(evaluateTool.description, /image_url/);
  assert.match(evaluateTool.description, /unverified/);
  assert.ok(evaluateTool.promptGuidelines.some((line: string) => /one question per region/.test(line)));
});
