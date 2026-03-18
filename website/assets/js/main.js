// IntersectionObserver — fade-in sections on scroll (fires once)
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.1 },
);

document.querySelectorAll(".fade-in").forEach((el) => observer.observe(el));

// Stagger grid children 80ms apart, then observe them
document.querySelectorAll(".grid-3, .grid-5-wrap").forEach((grid) => {
  grid.querySelectorAll(":scope > *").forEach((child, i) => {
    child.style.transitionDelay = `${i * 80}ms`;
    child.classList.add("fade-in");
    observer.observe(child);
  });
});

// Copy button — copies code block content to clipboard
document.querySelectorAll(".copy-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    const code = btn
      .closest(".code-block-wrapper")
      .querySelector("code").textContent;
    navigator.clipboard.writeText(code).catch(() => {});
    btn.textContent = "Copied!";
    setTimeout(() => (btn.textContent = "Copy"), 2000);
  });
});
