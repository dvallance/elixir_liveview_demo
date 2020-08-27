// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

let Hooks = {}
Hooks.ChatForm = {
  updated() {
    this.el.reset();
  }
}

Hooks.Chat = {
  updated() {
    console.dir(this.el);
  }
}

Hooks.Test = {
  updated() {
    console.log("UPDATED");
    console.dir(this.el);
  },
  mounted() {
    console.log("MOUNTED");
    console.dir(this.el);
  }
}

Hooks.Rolling = {
  diceKeyframes(dice_number) {
    let x, y;
    [x, y] = this.dicePosition(dice_number);
    return [
     {transform: "rotateY(0grad) rotateX(0grad)"},
     {transform: `rotateX(${x}grad) rotateY(${y}grad)`},
    ]
  },
  dicePosition(dice_number) {
    return ((dice_numer) => {
      switch(dice_number) {
      case 1: return [400, 825] //425
      case 2: return [400, 725]
      case 3: return [400, 625]
      case 4: return [400, 525]
      case 5: return [680, 400]
      case 6: return [480, 400]
      }
    })(dice_number)
  },
  positionDice(element) {
    const rolled = parseInt(element.dataset.rolled);
    if (rolled > 0) {
      const die = element.querySelector('.js-die');
      let x, y;
      [x, y] = this.dicePosition(rolled);
      die.style.transform = `rotateX(${x}grad) rotateY(${y}grad)`
    }
  },
  rollDice(element) {
    const rolling_number = parseInt(element.dataset.rolling);
    if (rolling_number > 0) {
      const die = element.querySelector('.js-die');
      die.animate(this.diceKeyframes(rolling_number), {duration: 2000, iterations: 1, fill: "forwards", easing: "ease"});
      //const dice_animation = die.animate(this.diceKeyframes(rolling_number), {duration: 2000, iterations: 1, fill: "forwards", easing: "ease"});
      //dice_animation.onfinish = () => {
      //  //this.pushEventTo("#game", "rolled", {rolled: rolling_number, player_name: player_name});
      //}
    }
  },
  mounted() {
    this.positionDice(this.el);
    this.rollDice(this.el);
  },
  updated() {
    this.positionDice(this.el);
    this.rollDice(this.el);
  },
  beforeUpdate() {
    this.positionDice(this.el);
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket

window.toggleInstructions = (element) => {
  const elem = element.parentNode.querySelector(".js-instructions");
  elem.classList.toggle("hidden");
  console.dir(elem);
};
