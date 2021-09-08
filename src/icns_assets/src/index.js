import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory as icns_idl, canisterId as icns_id } from 'dfx-generated/icns';

const agent = new HttpAgent();
const icns = Actor.createActor(icns_idl, { agent, canisterId: icns_id });

document.getElementById("clickMeBtn").addEventListener("click", async () => {
  const name = document.getElementById("name").value.toString();
  const greeting = await icns.greet(name);

  document.getElementById("greeting").innerText = greeting;
});
