---
name: rty-atlassian-mcp
description: Provides agents with access to Jira and Confluence via Atlassian's official cloud MCP server
---

# Enable agent usage of Jira and Confluence via Atlassian's official MCP server

Use this skill to set up and make good use of Atlassian's cloud MCP server.

## Instructions for setting up Atlassian MCP

If the user asks for it, provide help with initial configuration in the user's agent environment.

If the agent environment has a well-defined way to add MCP servers, prefer that.

* Codex: `codex mcp add`
* VS Code: Instruct user to run command [MCP: Add server...](command:workbench.mcp.addConfiguration).

User goal for initial setup: adding an MCP server configuration named `atlassian-cloud`, using transport type `http` (called `streamable-http` in MCP manifest format), and url `https://mcp.atlassian.com/v1/mcp`.

You can also reference this [MCP manifest file](assets/atlassian-cloud-manifest.json), as well as an example [mcp.json](assets/mcp.json).

**DON'T** try to use `https://mcp.atlassian.com/v1/manifest` because no such file is published.

Upon first start of the `atlassian-cloud` MCP server, the user should be asked to authorize in an OAuth browser flow.

## Instructions for using Atlassian MCP effectively at Riverty

If user asks about Jira or Confluence content, use `atlassian-cloud` MCP server. Use cloudId = "https://riverty.atlassian.net" (do NOT call getAccessibleAtlassianResources).

## Technical reference material

* If needed, e.g. to answer more detailed questions on how Atlassian MCP works, consult the [official Atlassian MCP Server README](https://github.com/atlassian/atlassian-mcp-server/blob/main/README.md).
