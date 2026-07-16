# ARIA Attributes

- Use ARIA attributes only when necessary (e.g., when semantic HTML cannot achieve the desired functionality).
  - Avoid using ARIA roles and attributes on elements that already have native semantics (e.g., don't add `role="button"` to a `<button>` element).
- Indicate current state of interactive elements (e.g., `aria-selected`, `aria-expanded`).
- Associate error messages with specific fields using `aria-describedby`.
- Use ARIA live regions for dynamic content (e.g., `aria-live="polite"` for non-critical updates, `aria-live="assertive"` for critical updates).
- Use `aria-hidden="true"` to hide decorative elements from screen readers.
- Add `aria-label` or `aria-labelledby` to provide descriptive labels for interactive elements when visible text is insufficient.

## Examples (❌ Bad vs ✅ Good):

```html
<!-- ❌ Bad examples -->
<a href="bad.example" role="button">Bad example</a>  <!-- Link has a new role -->

<button aria-hidden="true">Sign up</button> <!-- Button is hidden from screen readers but still visible to sighted users -->

<button aria-label="Click to open menu">Menu</button> <!-- Button has an aria-label but also has visible text -->

<label for="email">Email</label>
<input type="email" id="email" name="email" required> <!-- Input is not associated with the error message -->
<div id="error-message">Email is required</div>

<div class="alert">
  <!-- Dynamic content is added without using ARIA live regions, so screen readers won't announce it -->
</div>

<!-- ✅ Good examples -->
<dialog aria-labelledby="title"> <!-- Dialog has a title that is properly associated with aria-labelledby -->
  <h2 id="title">Colors</h2>
</dialog>

<svg aria-hidden="true"> <!-- SVG is decorative and hidden from screen readers -->
  <!-- Decorative SVG content -->
</svg>

<button aria-label="Menu"> <!-- Icon content--> </button> <!-- Button has an aria-label and no visible text -->

<label for="email">Email</label>
<input type="email" id="email" name="email" required aria-describedby="error-message"> <!-- Input is associated with the error message using aria-describedby -->
<div id="error-message">Email is required</div>

<div aria-live="assertive">
  <!-- Dynamic content is added to an ARIA live region, so screen readers will announce it -->
</div>
```