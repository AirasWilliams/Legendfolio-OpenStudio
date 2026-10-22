# Security reporting

Report vulnerabilities privately. Do not publish working credentials, private records, account tokens or a live exploit against other people's campaigns in an ordinary issue.

If this GitHub repository has **Private vulnerability reporting** enabled, use **Security → Report a vulnerability**. Otherwise, ask the maintainer for a private reporting channel without posting exploit details. This release does not designate an external security email address or promise a response SLA.

Include the build/version, affected component, minimal reproduction using accounts/data you control, expected boundary and observed result. Explain any access prerequisites and provide only the minimum redacted evidence required.

Relevant boundaries include personal character ownership, campaign ownership/membership, approved versus pending characters, DM-only notes, server-redacted party status, private dice, token/session handling and account/campaign isolation.

Use your own test instance for active security work. Do not probe another account's live campaign, cause service disruption or download private data to demonstrate a finding.

Supabase publishable/legacy anon keys are public browser configuration. Secret/service-role keys, database credentials and authentication/session tokens are sensitive. A publishable key's visibility alone is not a vulnerability; unintended access through that key or a policy/operation can be.

The application's optional cloud mode relies on authenticated backend checks and Row Level Security. Local DM selection, Interface Level and frontend capability flags must not confer cloud permissions. Private campaign data must be filtered at the backend, not merely hidden by interface styling.

Self-hosters must manage their own security updates, database backups, Auth/email settings, incident response and service credentials. Until a version-support policy is adopted, no historical build should be assumed to receive security backports.
