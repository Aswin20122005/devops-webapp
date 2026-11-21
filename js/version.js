// Show which commit this container was built from (version.json is written by the Dockerfile).
// On GitHub Pages there is no version.json, so the footer simply stays hidden.
fetch("version.json", { cache: "no-store" })
  .then((res) => (res.ok ? res.json() : Promise.reject(res.status)))
  .then(({ commit, built }) => {
    const footer = document.getElementById("build-info");
    footer.textContent = `Build ${commit.slice(0, 7)} · ${built}`;
    footer.hidden = false;
  })
  .catch(() => {});
