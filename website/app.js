const cards = [...document.querySelectorAll(".movie")];
const search = document.querySelector("#search");
const filters = [...document.querySelectorAll(".filter")];
const emptyState = document.querySelector("#empty-state");

let activeGenre = "All";

function updateCatalog() {
  const query = search.value.trim().toLowerCase();
  let visible = 0;

  cards.forEach((card) => {
    const title = card.dataset.title.toLowerCase();
    const genre = card.dataset.genre;

    const matchesQuery = title.includes(query);
    const matchesGenre = activeGenre === "All" || genre === activeGenre;
    const show = matchesQuery && matchesGenre;

    card.hidden = !show;
    if (show) visible++;
  });

  emptyState.hidden = visible > 0;
}

search.addEventListener("input", updateCatalog);

filters.forEach((button) => {
  button.addEventListener("click", () => {
    activeGenre = button.dataset.genre;

    filters.forEach((filter) => {
      const selected = filter === button;
      filter.classList.toggle("active", selected);
      filter.setAttribute("aria-pressed", String(selected));
    });

    updateCatalog();
  });
});

filters.forEach((button) => {
  button.setAttribute(
    "aria-pressed",
    String(button.dataset.genre === "All")
  );
});
