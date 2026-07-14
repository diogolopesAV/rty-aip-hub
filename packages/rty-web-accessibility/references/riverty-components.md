# Riverty Design System Components

When building accessible interfaces, prioritize using existing Riverty Design System components. These components have been built with accessibility in mind, meaning they already include the necessary semantic HTML, ARIA attributes, and keyboard navigation support.

## Guidelines

1. **Check the Component Library First:** Before creating a custom UI element (like a button, modal, or dropdown), verify if a corresponding component exists in the Riverty Design System.
2. **Use the Right Component for the Job:** Ensure that the component is used semantically correct according to its intended design purpose.
3. **Review Component Documentation:** Always read the specific accessibility documentation provided for the Riverty component you are implementing to understand its requirements and constraints.

By using Riverty components, you ensure consistency and save time while maintaining high accessibility standards throughout the application.

### Examples (❌ Bad vs ✅ Good):

```html
<!-- ❌ Bad example -->
<div class="custom-button" role="button" tabindex="0">Sign In</div>  <!-- Custom button lacks proper semantics and may not be fully accessible -->

<button>Sign In</button> <!-- Native button is better than a custom div, but using a Riverty button component is even better -->

<label for="email">Email:</label>
<input type="email" id="email" name="email"> <!-- Native form elements are good, but using Riverty form components can enhance accessibility and consistency -->

<!-- ✅ Good example -->
<r-button>Sign In</r-button> <!-- Use a Riverty button component that is built with accessibility in mind -->

<r-input type="email" label="Email" name="email"></r-input> <!-- Use a Riverty input component that includes proper labeling and accessibility features -->
```