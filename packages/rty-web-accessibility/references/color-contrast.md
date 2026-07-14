# Color Contrast

- Ensure a contrast ratio of at least **4.5:1** for normal text and **3:1** for large text.
- Ensure that interactive elements (e.g., buttons, links) have at least **3:1** contrast against adjacent color(s).
- Ensure that graphical objects (e.g., icons, chart lines) have at least **3:1** contrast against adjacent color(s).
- Do not convey information by color alone (e.g., use icons, text).

## Examples (❌ Bad vs ✅ Good):

```css
/* ❌ Bad example: insufficient contrast */
.information {
  background-color: #1a2236; /* Dark blue */
  color: #0a42d1; /* Blue text with insufficient contrast against the dark blue background */
}

input {
  border: 1px solid #9D9D9D; /* Light gray border with insufficient contrast against a white background */
}

svg {
  fill: #9D9D9D; /* Light gray fill with insufficient contrast against a white background */
  background-color: white;
}

/* ✅ Good example: sufficient contrast */
.information {
  background-color: #1a2236; /* Dark blue */
  color: #FFFFFF; /* White text for sufficient contrast */
}

input {
  border: 1px solid #000000; /* Black border for sufficient contrast against a white background */
}

svg {
  fill: #000000; /* Black fill for sufficient contrast against a white background */
  background-color: white;
}
```

```html
<!-- ❌ Bad example: using color alone to indicate invalidity -->
<input type="email" id="email" name="email" required style="border: 1px solid red;" aria-invalid="true">

<!-- ✅ Good example: using both color and text to indicate invalidity -->
<input type="email" id="email" name="email" required style="border: 1px solid red;" aria-invalid="true" aria-describedby="error-message">
<div style="color: red;" role="alert" id="error-message">Please enter a valid email address.</div>
```

## Check Color Contrast

1. Identify the hex codes for the background and foreground colors to be evaluated.
2. Always run the `scripts/check-contrast.js` tool. Replace the placeholders with the actual hex codes:

 ```bash
  node skills/design-system/rty-web-accessibility/scripts/check-contrast.js "<hex-color1>" "<hex-color2>"
 ```

3. Read the terminal output. If the script reports `FAIL` for the relevant text size (normal or large), warn the user that the colors are not WCAG compliant and suggest an alternative compliant color.
