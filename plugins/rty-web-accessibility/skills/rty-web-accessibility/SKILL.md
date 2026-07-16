---
name: rty-web-accessibility
description: Ensures all generated HTML and CSS/SCSS is WCAG 2.1/2.2 Level AA compliant. Use when creating a new web page, building a new feature, generating a component, auditing and fixing accessibility issues, implementing keyboard navigation, checking color contrast, and applying correct ARIA attributes. Do not use for native mobile apps, PDF accessibility, or non-web documents.
---

# Web Accessibility

Ensures all generated HTML and CSS/SCSS is WCAG 2.1/2.2 Level AA compliant.

## When to Use

Use this skill when:
- Building new components or pages from a description.
- Auditing and fixing accessibility issues in existing HTML and CSS/SCSS.
- Implementing correct keyboard navigation and focus management.
- Verifying color contrast ratios.
- Applying ARIA attributes to enhance semantic meaning.

Do not use when:
- Working with native mobile applications (iOS, Android).
- Creating or fixing accessible PDF documents.
- Checking accessibility for non-web document formats.

## Core Workflow

### Step 1: Mandatory Environment Check
Before generating any HTML/CSS, you MUST use the `read_file` or `grep_search` tool to check `package.json` for `@riverty/web-components`, alternatively, check the CDN links for usage, e.g. `<script src="https://cdn.riverty.design/components/{version}/dist/web-components/web-components.esm.js"></script>`.
- If `@riverty/web-components` or CDN usage is present, you MUST use Riverty web components (e.g., `<r-button>`, `<r-input>`) for the UI instead of native HTML elements.
- If it is not present, fall back to accessible native HTML.

### Step 2: Understand the Goal

1. If the user has provided HTML and/or CSS/SCSS, proceed to Step 2.
2. If not, ask the user to describe the component or page to build.
3. Generate a basic HTML structure and the associated CSS/SCSS based on the description.

### Step 3: Apply Accessibility Principles

Apply the following principles in order to the HTML and CSS/SCSS code.

1. **Apply Document Setup**: Ensure correct `lang` attributes and `<title>` tags. For details, read `references/document-setup.md`.
2. **Use Riverty Design System Components**:
  - NEVER generate native `<input>`, `<button>`, or other raw form elements without checking for Riverty equivalents first.
  - Read `references/riverty-components.md` for proper syntax and implementation of the components verified in Step 1.
3. **Use Semantic HTML Structure**: Employ semantic elements for headings, forms, main, nav, header, footer, tables, and lists. For details, read `references/html-structure.md`.
4. **Implement ARIA Attributes Correctly**: Manage ARIA usage for states, live regions, and labels where semantic HTML is insufficient. For details, read `references/aria-attributes.md`.
5. **Ensure Keyboard Navigation**: Manage tab order, focus, and interactive elements. For details, read `references/keyboard-navigation.md`.
6. **Check Color Contrast**: Verify that text and interactive elements meet color contrast ratios. For details and tool usage, read `references/color-contrast.md`.
7. **Follow Best Practices**: Implement skip links, accessible touch targets, and image alternatives. For details, read `references/best-practices.md`.

### Step 4: Present the Result

1. Start your response by explicitly stating: "Riverty Web Components detected in package.json. Proceeding with Riverty components." or "Riverty Web Components not found. Proceeding with native HTML."
2. Provide the modified HTML to the user, if it was changed.
3. Provide the modified CSS/SCSS to the user, if it was changed.
4. Explain the key accessibility improvements that were made.
