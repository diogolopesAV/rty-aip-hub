# Document Setup

- Include a valid `lang` attribute on the `<html>` tag to ensure screen readers use the correct pronunciation rules.
- Provide a unique, descriptive `<title>` tag for every page.

## Examples (❌ Bad vs ✅ Good):

```html
<!-- ❌ Bad example: missing language and generic title -->
<html>
<head>
    <title>Page</title>
</head>
<body>...</body>
</html>

<!-- ✅ Good example: valid language and descriptive title -->
<html lang="en">
<head>
    <title>Dashboard - My App</title>
</head>
<body>...</body>
</html>
```