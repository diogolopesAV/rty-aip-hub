# HTML Structure

- Use semantic elements over non-semantic with ARIA roles when possible, e.g. `button` instead of `div role="button"`.
- Don't skip heading levels (e.g., don't jump from `h1` to `h3`).
- Use one `h1` per page with a descriptive heading text.
- Use proper landmark elements: `main` to wrap the main content of the page, `nav` for navigation links, `aside` for complementary content, `article` for self-contained content, `header` for introductory content, and `footer` for footer content.
- Connect `label` elements to form controls using `for` and `id` attributes.
- Use `fieldset` and `legend` to group related form controls.
- Use `table` elements for tabular data, not for layout.
- Use `th` for table headers and associate them with data cells using `scope` or `headers` attributes.
- Use `ol` or `ul` for lists.

## Examples (❌ Bad vs ✅ Good):

```html
<!-- ❌ Bad example: using non-semantic elements -->
<div class="main">
  <div class="heading">App Name</div>
  <div class="form-group"> 
    <!-- Inputs without label, only with placeholder -->
    <input type="text" placeholder="Enter your email">
    <input type="text" placeholder="Enter your password">
    <span role="button" tabindex="0" onclick="signIn()">Sign in</span>
  </div>
</div>

<!-- ✅ Good example: using semantic elements -->
<main>
    <h1>App Name</h1>
    <form>
        <!-- Labels are associated with inputs using for and id attributes -->
        <label for="email">Email</label>
        <input id="email" type="email" name="email" required autocomplete="email">
        <label for="password">Password</label>
        <input id="password" type="password" name="password" required minlength="8" autocomplete="current-password">
        <button type="submit" onclick="signIn()">Sign in</button>
    </form>
</main>
```