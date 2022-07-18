<template>
  <div class="container">
    <button
      @keydown.down="open"
      @keydown.enter.prevent
      @click="open"
      :class="selected?.id ? 'selected' : ''"
      ref="button"
    >
      <span></span>

      {{ selected?.name || "Select moon..." }}
    </button>

    <div v-show="toggled" class="searchContainer" ref="searchContainer">
      <input
        @input="search($refs.search.value)"
        @blur="close"
        @keydown.esc="close"
        @keydown.down.prevent="move('down')"
        @keydown.up.prevent="move('up')"
        @keydown.enter="
          selected = searchResults[highlightedResult];
          $refs.search.blur();
        "
        type="text"
        ref="search"
        placeholder="Search moons..."
      />
      <img src="/search.svg" height="15" />

      <ul v-show="searchResults.length">
        <li
          @mousedown="selected = result"
          @mouseover="highlightedResult = index"
          @mouseout="highlightedResult = -1"
          v-for="(result, index) in searchResults"
          :key="result.id"
          :class="index == highlightedResult ? 'highlighted' : ''"
        >
          <span></span>{{ result.name }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script lang="ts">
import axios from "axios";
import { Options, Vue } from "vue-class-component";

@Options({
  emits: ["select"],
})
export default class MoonSearch extends Vue {
  toggled = false;
  searchResults = [];
  highlightedResult = -1;
  selected = {};
  declare $refs: {
    search: HTMLInputElement;
    button: HTMLButtonElement;
    searchContainer: HTMLDivElement;
  };

  async search(moon: string): Promise<void> {
    this.highlightedResult = -1;

    if (moon) {
      const res = await axios.get(`${process.env.VUE_APP_API_URL}/moon/search/${moon}`);
      this.searchResults = res.data.results;
    } else {
      this.searchResults = [];
    }
  }

  tapOusideElement(e: TouchEvent): void {
    if (!this.$refs.searchContainer.contains(<Element>e.target)) {
      this.close();
    }
  }

  close(): void {
    window.removeEventListener("touchstart", this.tapOusideElement);
    this.toggled = false;
    this.$emit("select", this.selected);
    setTimeout(() => this.$refs.button.focus(), 0); // setTimeout of 0 needed so that element exists in DOM when focusing
  }

  open(): void {
    window.addEventListener("touchstart", this.tapOusideElement);
    this.highlightedResult = -1;
    this.toggled = true;
    setTimeout(() => this.$refs.search.focus(), 0); // setTimeout of 0 needed so that element exists in DOM when focusing
  }

  move(direction: string): void {
    if (!this.$refs.search.value) return;

    if (direction == "up" && this.highlightedResult > 0) {
      this.highlightedResult -= 1;
    } else if (
      direction == "down" &&
      this.highlightedResult < this.searchResults.length - 1
    ) {
      this.highlightedResult += 1;
    }
  }
}
</script>

<style scoped>
.container {
  width: 275px;
  max-width: 275px;
  position: relative;
}

button {
  background-color: var(--backgroundSecondary);
  color: var(--textTertiary);
  font-size: 20px;

  border: none;
  border-radius: 15px;

  display: flex;
  align-items: center;
  position: relative;

  width: 100%;
  padding: 10px 15px 10px 15px;

  cursor: pointer;
}
button.selected {
  color: var(--textPrimary);
}
button > span {
  width: 15px;
  height: 15px;
  margin-right: 5px;

  border-radius: 100%;
  border: 1px dashed var(--textTertiary);
}
button:after {
  content: "";
  background: var(--textTertiary);
  width: 1px;
  height: 10px;
  border-radius: 15px;
  transform: rotate(-45deg);
  position: absolute;
  right: 25px;
  top: 17px;
}
button:before {
  content: "";
  background: var(--textTertiary);
  width: 1px;
  height: 10px;
  border-radius: 15px;
  transform: rotate(45deg);
  position: absolute;
  right: 18px;
  top: 17px;
}

.searchContainer {
  width: 100%;
  position: absolute;
  top: 0;
  border-radius: 15px;
  background-color: var(--backgroundSecondary);
  box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.15);
}
input {
  color: var(--textPrimary);
  font-size: 20px;

  border: none;
  outline: none;
  border-radius: 15px;

  display: flex;
  align-items: center;
  position: relative;

  padding: 10px 15px 10px 30px;
  box-sizing: border-box;
  width: 100%;

  cursor: pointer;
}
input::placeholder {
  color: var(--textTertiary);
}
img {
  position: absolute;
  top: 14px;
  left: 10px;
}

ul {
  list-style: none;
  padding-bottom: 15px;
}
li {
  padding: 5px 15px;
  color: var(--textPrimary);
  display: flex;
  align-items: center;
  cursor: pointer;
}
li > span {
  width: 15px;
  height: 15px;
  margin-right: 5px;
  display: inline-flex;

  background-color: var(--textTertiary);
  border-radius: 100%;
}

li.highlighted {
  background-color: #006cff11;
  color: #006cff;
}
li.highlighted > span {
  background-color: #006cff;
}
</style>
