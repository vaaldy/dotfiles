#!/usr/bin/env node
// Read-only Jira MCP pagination. OAuth stays in pi-mcp-adapter's secure store.
import { existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { homedir } from 'node:os';
import { join } from 'node:path';

const agentDir = join(homedir(), '.pi/agent');
const envPath = join(agentDir, '.env');
if (existsSync(envPath)) process.loadEnvFile(envPath);
const cloudId = process.env.JIRA_CLOUD_ID;
if (!cloudId) throw new Error('JIRA_CLOUD_ID is required in ~/.pi/agent/.env');
const require = createRequire(join(agentDir, 'npm/package.json'));
const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StreamableHTTPClientTransport } = require('@modelcontextprotocol/sdk/client/streamableHttp.js');
const { getMcpOAuthTokensForUrl } = await import(require.resolve('pi-mcp-adapter/oauth'));
const url = 'https://mcp.atlassian.com/v1/mcp/authv2';
const [jql, fields] = process.argv.slice(2);
if (!jql || !fields) throw new Error('Expected JQL and comma-separated fields');
const tokens = await getMcpOAuthTokensForUrl('jira', url);
if (!tokens?.accessToken) throw new Error('Jira MCP is not authenticated; connect it in Pi first');
const client = new Client({ name: 'pi-jira-index', version: '1.0.0' });
try {
  await client.connect(new StreamableHTTPClientTransport(new URL(url), {
    requestInit: { headers: { Authorization: `Bearer ${tokens.accessToken}` } },
  }));
  const pages = [];
  let nextPageToken;
  do {
    const args = { cloudId, jql, fields: fields.split(','), maxResults: 100, searchResultMode: 'issues' };
    if (nextPageToken) args.nextPageToken = nextPageToken;
    const result = await client.callTool({ name: 'searchJiraIssuesUsingJql', arguments: args });
    if (result.isError) throw new Error('Jira MCP search failed');
    const page = result.structuredContent ?? JSON.parse(result.content.find(x => x.type === 'text').text);
    if (!Array.isArray(page.issues)) throw new Error('Jira MCP search returned no issues array');
    pages.push(page.issues);
    if (page.isLast) break;
    nextPageToken = page.nextPageToken;
    if (!nextPageToken) throw new Error('Jira MCP pagination ended without isLast or nextPageToken');
  } while (true);
  process.stdout.write(JSON.stringify(pages));
} finally {
  await client.close();
}
