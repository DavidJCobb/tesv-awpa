import { GroupCollection } from "./awpa-groups.js";

let form = document.querySelector(`div[slot="payload-uploads"]`);
let load = form.querySelector(`input[type="button"]`);
load.addEventListener("click", async (e) => {
   let controls = form.querySelectorAll("input[type='file']");
   let files    = [];
   controls.forEach((node) => {
      for(let file of node.files) {
         files.push(file);
      }
   });
   
   let collection = new GroupCollection();
   for(let file of files) {
      let text = await file.text();
      let dom  = (new DOMParser()).parseFromString(text, "application/xml");
      
      collection.load_from_payload(dom.documentElement);
   }
   document.querySelector("awpa-map").set_group_collection(collection);
});