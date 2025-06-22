# Troubleshooting

Common issues and solutions for Aurora UIX.

## Compilation Errors

- Ensure all dependencies are installed.
- Check that your resource and layout macros are correct.

## UI Not Updating

- Make sure LiveView is connected.
- Check for errors in the browser console.

## Styling Issues

- Verify your Tailwind configuration includes all necessary paths.
- Rebuild assets with `mix uix.test.assets.build`.

## Database Issues

- Ensure PostgreSQL is running and the correct database is configured.
- Run migrations if you see missing table errors.

## Still Stuck?

Open an issue on [GitHub](https://github.com/wadvanced/aurora_uix/issues).
