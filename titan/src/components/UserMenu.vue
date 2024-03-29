<template>
  <div>
    <button @click="openMenu" @keydown="menuButtonKeyDown" ref="button">
      {{ username }}
    </button>
    <ul v-show="showMenu" ref="menu">
      <li
        v-for="(option, index) in options"
        tabindex="0"
        :key="option"
        :ref="option"
        @click="menuClick(option)"
        @mouseover="$event.target.focus()"
        @keydown.prevent="selectOption($event, option, index)"
        @blur="checkFocus"
      >
        {{ option }}
      </li>
    </ul>
  </div>
</template>

<script lang="ts">
import axios from "axios";
import { Options, Vue } from "vue-class-component";

@Options({
  name: "UserMenu",
  props: {
    username: String,
  },
})
export default class Menu extends Vue {
  username!: string;
  options = ["Settings", "Profile", "Create post", "Create moon", "Log out"];

  selected = this.options[0];
  showMenu = false;
  declare $refs: {
    button: HTMLButtonElement;
    menu: HTMLUListElement;
    [key: string]: unknown;
  };

  checkFocus(): void {
    // setTimeout is needed, otherwise the active element return previously selected element, not current
    setTimeout(() => {
      if (document?.activeElement?.parentNode != this.$refs.menu) {
        this.showMenu = false;
        window.removeEventListener("touchstart", this.checkClickTarget);
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

  checkClickTarget(e: TouchEvent): void {
    if (!this.$refs.menu.contains(<Element>e.target)) {
      this.showMenu = false;
      window.removeEventListener("touchstart", this.checkClickTarget);
      this.$refs.button.focus();
    }
  }

  openMenu(): void {
    this.showMenu = true;
    window.addEventListener("touchstart", this.checkClickTarget);
    // if setTimeout is removed, the menu option (li) won't focus.
    setTimeout(() => {
      (<HTMLElement[]>this.$refs[this.options[0]])[0].focus();
    }, 0);
  }

  selectOption(e: KeyboardEvent, option: string, index: number): void {
    const nextSibling = (<HTMLElement[]>this.$refs[this.options[index + 1]] || [])[0];
    const previousSibling = (<HTMLElement[]>this.$refs[this.options[index - 1]] || [])[0];
    switch (e.code) {
      case "Enter":
      case "Space":
        this.menuClick(option);
        break;

      case "ArrowDown":
        if (nextSibling) {
          nextSibling.focus();
        }
        break;

      case "ArrowUp":
        if (previousSibling) {
          previousSibling.focus();
        }
        break;

      case "Escape":
        (<HTMLLIElement>e.target).blur();
        break;

      default:
        break;
    }
  }

  menuClick(option: string): void {
    this.$refs.button.focus();
    this.showMenu = false;

    switch (option) {
      case "Log out":
        axios
          .delete(`${process.env.VUE_APP_API_URL}/user/logout`, {
            withCredentials: true,
          })
          .then(() => {
            this.$store.dispatch("logout");
            this.$router.go(0);
          });
        break;

      case "Create moon":
        this.$router.push({ name: "CreateMoon" });
        break;

      case "Create post":
        this.$router.push({ name: "CreatePost" });
        break;

      case "Settings":
        this.$router.push({ name: "Settings" });
        break;

      case "Profile":
        this.$router.push({ name: "Profile", params: { username: this.username } });
        break;
    }
  }
}
</script>

<style scoped>
div {
  position: relative;
}

button {
  border: var(--backgroundTertiary) 1px solid;
  color: var(--primaryText);
  cursor: pointer;
  font-size: 16px;
  padding: 9px 25px 10px 15px;
  border-radius: 15px;
  background: none;
  position: relative;
  text-align: left;
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
  top: 16px;
  right: 16px;
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
  top: 16px;
  right: 12px;
}

ul {
  position: absolute;
  top: 0px;
  right: 0;
  background: var(--backgroundSecondary);
  list-style: none;
  border-radius: 15px;
  width: max-content;
  box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.2);
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
li:first-child {
  border-radius: 15px 15px 0 0;
}
li:last-child {
  border-radius: 0 0 15px 15px;
  color: #ff0000;
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
</style>
