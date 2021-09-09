// import { icns } from "../../declarations/icns";

// document.getElementById("clickMeBtn").addEventListener("click", async () => {
//   const name = document.getElementById("name").value.toString();
//   // Interact with icns actor, calling the greet method
//   const greeting = await icns.greet(name);

//   document.getElementById("greeting").innerText = greeting;
// });

import React, { Suspense } from "react";
import ReactDOM from "react-dom";
import App from "./App.jsx";

// import { GlobalStateProvider } from 'globalState'
// import 'globalStyles'
// import './i18n'
// import { handleNetworkChange } from './utils/utils'

window.addEventListener("load", async () => {
  // const { client, networkId } = await handleNetworkChange()
  ReactDOM.render(
    <Suspense fallback={null}>
      {/* <GlobalStateProvider> */}
      {/* <App initialClient={client} initialNetworkId={networkId} /> */}
      <App />
      {/* </GlobalStateProvider> */}
    </Suspense>,
    // <div>hi</div>,
    document.getElementById("root"),
  );
});
