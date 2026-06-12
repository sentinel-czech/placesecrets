# Local Supabase Development

Run from `backend/supabase/`:

```bash
npx supabase start
npx supabase stop
npx supabase db reset   # re-apply migrations + seed
```

## Development Tools

| Service  | URL                              |
|----------|----------------------------------|
| Studio   | http://127.0.0.1:54323           |
| Mailpit  | http://127.0.0.1:54324           |
| MCP      | http://127.0.0.1:54321/mcp       |

## APIs

| Endpoint       | URL                                   |
|----------------|---------------------------------------|
| Project URL    | http://127.0.0.1:54321                |
| REST           | http://127.0.0.1:54321/rest/v1        |
| GraphQL        | http://127.0.0.1:54321/graphql/v1     |
| Edge Functions | http://127.0.0.1:54321/functions/v1   |

## Database

```
postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

## Authentication Keys

| Key         | Value                                          |
|-------------|------------------------------------------------|
| Publishable | `sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH` |
| Secret      | `sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz`      |

## Storage (S3)

| Field      | Value                                                              |
|------------|--------------------------------------------------------------------|
| URL        | http://127.0.0.1:54321/storage/v1/s3                               |
| Access Key | `625729a08b95bf1b7ff351a663f3a23c`                                 |
| Secret Key | `850181e4652dd023b7a98c58ae0d2d34bd487ee0cc3254aed6eda37307425907` |
| Region     | `local`                                                            |
