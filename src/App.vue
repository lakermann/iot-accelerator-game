<template>
  <em class="bi bi-controller" style="font-size: 7rem; color: cornflowerblue;"></em>
  <h1>IoT Accelerometer Game</h1>
  <Accelerometer/>
</template>

<script>
import Accelerometer from './components/Accelerometer.vue';

export default {
  name: 'App',
  components: {
    Accelerometer,
  },
};
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
