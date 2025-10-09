import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import coldbox from "coldbox-vite-plugin";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
	plugins: [
		vue(),
		tailwindcss(),
		coldbox({
			input: [ "resources/assets/css/app.css", "resources/assets/js/app.js" ],
			refresh: true,
			publicDirectory: "public/includes"
		})
	],
});