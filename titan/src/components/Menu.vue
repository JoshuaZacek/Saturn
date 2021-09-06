<template>
  <div>
    <button @click="openMenu" @keydown="menuButtonKeyDown" ref="button">
      {{ selected }}
    </button>
    <ul v-show="showMenu" ref="menu">
      <li
        v-for="(option, index) in options"
        tabindex="0"
        :key="option"
        :ref="option"
        @click="menuClick(option)"
        @mouseover="$refs[options[index]].focus()"
        @keydown.prevent="selectOption($event, option, index)"
        @blur="checkFocus"
      >
        <span />
        {{ option }}
      </li>
    </ul>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";

@Options({
  name: "Menu",
  props: {
    options: Array,
  },
  watch: {
    selected: "updateMenu",
  },
  emits: ["change"],
})
export default class Menu extends Vue {
  options!: Array<string>;

  selected = this.options[0];
  showMenu = false;
  declare $refs: {
    button: HTMLButtonElement;
    menu: HTMLUListElement;
    [key: string]: HTMLElement;
  };

  checkFocus(): void {
    setTimeout(() => {
      // Don't touch, otherwise the active element return previously selected element, not current
      if (document?.activeElement?.parentNode != this.$refs.menu) {
        this.showMenu = false;
        this.$refs.button.focus();
      }
    }, 0);
  }

  menuButtonKeyDown(e: KeyboardEvent): void {
    if (e.code == "ArrowDown" || e.code == "Space") {
      e.preventDefault();
      this.openMenu();
    } else if (e.code == "Enter") {
      e.preventDefault();
    }
  }

  openMenu(): void {
    this.showMenu = true;
    setTimeout(() => {
      // this is needed for the focus to work, don't remove
      this?.$refs[this.selected].focus();
    }, 0);
  }

  selectOption(e: KeyboardEvent, option: string, index: number): void {
    if (e.code == "Enter" || e.code == "Space") {
      this.menuClick(option);
    } else if (e.code == "ArrowDown") {
      const nextSibling = this.$refs[this.options[index + 1]];
      if (nextSibling) {
        nextSibling.focus();
      }
    } else if (e.code == "ArrowUp") {
      const previousSibling = this.$refs[this.options[index - 1]];
      if (previousSibling) {
        previousSibling.focus();
      }
    }
  }

  menuClick(option: string): void {
    this.$refs.button.focus();
    if (this.selected == option) {
      this.showMenu = false;
    } else {
      this.selected = option;
    }
  }

  updateMenu(selectedOption: string, oldOption: string): void {
    this.$refs[oldOption].classList.remove("selected");
    this.$refs[selectedOption].classList.add("selected");
    this.selected = selectedOption;
    this.showMenu = false;
    this.$emit("change", selectedOption);
  }

  mounted(): void {
    this.$refs[this.selected].classList.add("selected");
  }
}
</script>

<style scoped>
div {
  position: relative;
}

button {
  border: none;
  cursor: pointer;
  font-size: 14px;
  padding: 5px 25px 5px 15px;
  border-radius: 15px;
  color: #000;
  background: var(--backgroundTertiary);
}
button:after {
  content: "";
  background: #000;
  display: block;
  width: 1px;
  height: 6px;
  border-radius: 15px;
  transform: rotate(-45deg);
  position: absolute;
  top: 12px;
  right: 18px;
}
button:before {
  content: "";
  background: #000;
  display: block;
  width: 1px;
  height: 6px;
  border-radius: 15px;
  transform: rotate(45deg);
  position: absolute;
  top: 12px;
  right: 14px;
}
button:hover {
  background: #e2e2e2;
}
button:active {
  background: #d6d6d6;
}

ul {
  position: absolute;
  top: 0;
  left: 0;
  background: var(--backgroundSecondary);
  list-style: none;
  border-radius: 15px;
  width: max-content;
}

li {
  text-align: center;
  padding: 12.5px 30px;
  position: relative;
  cursor: pointer;
  outline: none;
}

li:focus {
  background: var(--backgroundTertiary);
}
li:first-child:focus {
  border-radius: 15px 15px 0 0;
}
li:last-child:focus {
  border-radius: 0 0 15px 15px;
}
li:not(:last-child):after {
  content: "";
  background: var(--backgroundTertiary);
  display: block;
  width: 100%;
  height: 1px;
  position: absolute;
  bottom: 0;
  left: 0;
}
/* Tick mark */
li.selected > span {
  position: absolute;
  display: inline-block;
}
li.selected > span:after {
  content: "";
  background: #000;
  display: block;
  width: 2px;
  height: 8px;
  border-radius: 15px;
  transform: rotate(-45deg);
  position: absolute;
  bottom: -16px;
  left: -18px;
}
li.selected > span:before {
  content: "";
  background: #000;
  display: block;
  width: 2px;
  height: 14px;
  border-radius: 15px;
  transform: rotate(35deg);
  position: absolute;
  bottom: -16px;
  left: -12px;
}
</style>