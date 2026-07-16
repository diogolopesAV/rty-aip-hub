# Keyboard Navigation

- Ensure that interactive elements are keyboard accessible (e.g. using `button` element).
- Ensure focus orders are logical and intuitive.
- Provide visible focus indicators.
- Restore focus to a trigger element after a modal dialog or popover is closed.

## Examples (❌ Bad vs ✅ Good):

```html
<!-- ❌ Bad examples -->
<div role="button" tabindex="0" onclick="openMenu()">Menu</div> <!-- Non-semantic element does not have built-in keyboard support -->

<button tabindex="1">First</button> <!-- Incorrect tabindex value can disrupt natural tab order -->

<!-- ✅ Good examples -->
<button onclick="openMenu()">Menu</button> <!-- Semantic button element is keyboard accessible -->

<button>First</button> <!-- Natural tab order is maintained without using tabindex -->
```

```css
/* ❌ Bad example: no visible focus indicator */
button:focus {
  outline: none;
}

/* ✅ Good example: visible focus indicator with sufficient contrast for both dark and light themes */
button:focus {
  box-shadow: 0 0 0 6px #ffffff;
  outline: 2px solid #0071e3;
  outline-offset: 2px;
}
```

```html
<!-- ❌ Bad example: focus is not restored after modal closes -->
<button onclick="openModal()">Open modal</button>
<dialog id="modal">
  <button onclick="closeModal()">Close</button>
</dialog>

<script>
  function openModal() {
    document.getElementById('modal').showModal();
  }
  function closeModal() {
    document.getElementById('modal').close();
    // Focus is lost — user is dropped back to the top of the page
  }
</script>

<!-- ✅ Good example: focus is restored to the trigger element after modal closes -->
<button id="open-btn" onclick="openModal()">Open modal</button>
<dialog id="modal">
  <button onclick="closeModal()">Close</button>
</dialog>

<script>
  function openModal() {
    document.getElementById('modal').showModal();
  }
  function closeModal() {
    document.getElementById('modal').close();
    document.getElementById('open-btn').focus(); // Restore focus to the trigger
  }
</script>
```