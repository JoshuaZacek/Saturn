<template>
  <div>
    <h3>Content does not exist</h3>
    <p>
      The content you requested may have been modified, deleted, or may have a different
      spelling.
    </p>

    <button @click="$router.push({ name: 'Home' })">Go to the front page</button>
  </div>
</template>

<style scoped>
div {
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
  gap: 5px;

  position: absolute;
  top: calc(50% + 25px);
  transform: translateY(-50%);
}

h3 {
  color: var(--textPrimary);
}

p {
  color: var(--textSecondary);
  max-width: 60%;
  text-align: center;
}

button {
  padding: 5px 10px;
  display: block;

  border: none;
  border-radius: 12px;
  cursor: pointer;

  font-weight: 500;
  font-size: 15px;

  background-color: transparent;
  color: #006cff;
}
button:hover {
  background-color: #006cff11;
}
</style>
