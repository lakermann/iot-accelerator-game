<template>
  <div>
    <ul>
      <li><input v-model="username" placeholder="Set Username"></li>
    </ul>
    <ul>
      <li>
        <button v-on:click="start" v-if="!isRunning">Start Game</button>
        <button v-on:click="stop" v-if="isRunning">Stop Game</button>
      </li>
      <li><small>Motion Listener Status: {{ motionListenerStatus }}</small></li>
      <li><small>HTTP Status: {{ httpStatus }}</small></li>
    </ul>
    <ul>
      <li>X-axis: {{ acceleration.x }} m/s<sup>2</sup></li>
      <li>Y-axis: {{ acceleration.y }} m/s<sup>2</sup></li>
      <li>Z-axis: {{ acceleration.z }} m/s<sup>2</sup></li>
      <li>Data Interval: {{ interval }} ms
      </li>
    </ul>
  </div>
</template>

<script>
import axios from 'axios';

axios.defaults.baseURL = process.env.VUE_APP_POST_URL;
axios.defaults.headers.common.Authorization = process.env.VUE_APP_POST_AUTHORIZATION_HEADER;

export default {
  name: 'Accelerometer',

  data() {
    return {
      running: false,
      username: '',
      interval: 0,
      acceleration: {
        x: 0,
        y: 0,
        z: 0,
      },
      httpStatus: 'n/a',
      motionListenerStatus: 'n/a',
    };
  },

  computed: {
    isRunning() {
      return this.running;
    },
  },

  methods: {
    start() {
      this.running = true;
      if (window.DeviceMotionEvent && typeof window.DeviceMotionEvent.requestPermission === 'function') {
        window.DeviceMotionEvent.requestPermission()
          .then((permissionState) => {
            if (permissionState === 'granted') {
              window.addEventListener('devicemotion', this.motionHandler);
              this.motionListenerStatus = 'Permission granted';
            } else {
              this.motionListenerStatus = 'Permission not granted';
            }
          })
          .catch((error) => {
            this.motionListenerStatus = error.message;
          });
      } else {
        // handle regular non iOS 13+ devices
        window.addEventListener('devicemotion', this.motionHandler);
        this.motionListenerStatus = 'Permission granted';
      }
    },
    stop() {
      this.running = false;
      window.removeEventListener('devicemotion', this.motionHandler);
    },
    motionHandler(event) {
      const {
        acceleration,
        interval,
      } = event;
      this.acceleration = {
        x: Number(acceleration.x.toFixed(2)),
        y: Number(acceleration.y.toFixed(2)),
        z: Number(acceleration.z.toFixed(2)),
      };
      this.interval = Number(interval.toFixed(2));
    },
    async postAcceleration() {
      try {
        const response = await axios.post('/', {
          acceleration: this.acceleration,
          interval: this.interval,
          username: this.username,
        });
        this.httpStatus = response.status;
      } catch (error) {
        this.httpStatus = error.message;
      }
    },
  },

  mounted() {
    setInterval(() => {
      if (this.running) {
        this.postAcceleration();
      }
    }, process.env.VUE_APP_POST_INTERVAL);
  },
};
</script>

<style scoped>
ul {
  list-style-type: none;
  padding: 0;
}
</style>
