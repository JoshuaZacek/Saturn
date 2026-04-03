<template>
  <button />
</template>

<style scoped>
button {
  position: absolute;
  top: 15px;
  right: 15px;

  width: 25px;
  height: 25px;

  border: none;
  border-radius: 100%;
  cursor: pointer;

  background-color: #006cff11;
}
button:before {
  content: "";
  width: 2px;
  height: 15px;
  background-color: #006cff;
  position: absolute;
  top: 5px;
  left: 11.5px;
  border-radius: 1px;
  transform: rotate(-45deg);
}
button:after {
  content: "";
  width: 2px;
  height: 15px;
  background-color: #006cff;
  position: absolute;
  top: 5px;
  left: 11.5px;
  border-radius: 1px;
  transform: rotate(45deg);
}
</style>
