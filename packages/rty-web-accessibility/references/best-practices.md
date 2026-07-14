# Best Practices

## Navigation

- Add skip links to allow users to bypass repetitive content. You can visually hide skip links until they receive focus to avoid cluttering the UI for sighted users.

### Examples (❌ Bad vs ✅ Good):

```html
<!-- ❌ Bad examples: no skip link -->
<nav>
  <!-- Navigation links -->
</nav>
<main>
  <!-- Main content -->
</main>

<!-- ✅ Good example: with skip link -->
<a href="#main-content" class="skip-link">Skip to main content</a>
<nav>
  <!-- Navigation links -->
</nav>
<main id="main-content">
  <!-- Main content -->
</main>
```

```css
/* ❌ Bad example: using display:none removes the skip link from keyboard focus entirely */
.skip-link {
  display: none;
}

/* ✅ Good example: skip link is visually hidden until it receives focus */
.skip-link:not(:focus):not(:active) {
  clip: rect(0 0 0 0);
  clip-path: inset(50%);
  height: 1px;
  overflow: hidden;
  position: absolute;
  white-space: nowrap;
  width: 1px;
}
```

## Interactive Elements

- Ensure proper size and spacing of interactive elements for touch targets (at least `24x24 pixels`).
  - For enhanced accessibility, consider providing even larger touch targets (e.g., `48x48 pixels`).
- Provide sufficient spacing between interactive elements to prevent accidental activation.

### Examples (❌ Bad vs ✅ Good):

```css
/* ❌ Bad example: small touch target and no spacing between elements */
button {
  width: 1.25rem; /* 20px */
  height: 1.25rem; /* 20px */
  margin: 0;
}

/* ✅ Good example: large enough touch target with sufficient spacing */
button {
  width: 1.5rem; /* 24px */
  height: 1.5rem; /* 24px */
  margin: 0.5rem; /* spacing between elements */
}
```

## Images & Media

Non-text content must have a text alternative so that screen readers can convey its meaning to users.

- Provide text alternatives for non-text content (e.g., `alt` attributes for images).
- Use `alt=""` attributes for decorative images to allow screen readers to skip them.

### Examples (❌ Bad vs ✅ Good):

```html
<!-- ❌ Bad examples -->
<img src="logo.png"> <!-- Image has no alt attribute, so screen readers won't know what it is -->

<a href="home.html">
  <img src="logo.png" alt=""> <!-- Image has an empty alt attribute, so screen readers will skip it, but it is a functional link, so it should have a descriptive alt attribute to convey its purpose -->
</a>

<img src="shampoo.png" alt="Image of a shampoo"> <!-- Image has an alt attribute, but it's not descriptive enough to convey the content or purpose of the image -->

<!-- ✅ Good examples -->
<img src="logo.png" alt="Company Logo"> <!-- Image has a descriptive alt attribute for screen readers -->

<img src="image.png" alt=""> <!-- Image is decorative and has an empty alt attribute, so screen readers will skip it -->

<a href="home.html">
    <img src="logo.png" alt="Company home"> <!-- Image has a descriptive alt attribute that conveys the content and purpose of the image -->
</a>

<img src="shampoo.png" alt="A bottle of shampoo with a blue label"> <!-- Image has a descriptive alt attribute that conveys the content and purpose of the image -->
```

## Zoom & Scaling

- Support zoom and text resizing without loss of content or functionality (e.g., use `rem`, `em`, or `%` units instead of `px` for font sizes, heights, margins).

```css
/* ❌ Bad example: using fixed pixel units */
.information {
  margin-top: 4px;
  width: 100px;
  height: 40px;
  font-size: 16px;
}

/* ✅ Good example: using relative units */
.information {
  margin-top: 0.25rem; /* 4px */
  width: 6.25rem; /* 100px */
  height: 2.5rem; /* 40px */
  font-size: 1rem; /* 16px */
}
```

- Don't disable user scaling on mobile devices (e.g., avoid `user-scalable=no`, `maximum-scale=1.0` in the viewport meta tag).

```html
<!-- ❌ Bad example: disabling user scaling -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

<!-- ✅ Good example: allowing user scaling -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

## Motion & Animation

- Disable CSS animations and transitions using `prefers-reduced-motion`.

### Examples (❌ Bad vs ✅ Good):

```css 
/* ❌ Bad example: no support for reduced motion */
.spinner {
  animation: spin 1s linear infinite;
}

/* ✅ Good example: support for reduced motion */
@media (prefers-reduced-motion: reduce) {
  .spinner {
    animation: none; /* Disable animation for users who prefer reduced motion */
  }
}
```