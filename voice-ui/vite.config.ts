import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { ViteAliases } from 'vite-aliases';

export default defineConfig({
  plugins: [react(), ViteAliases()],
  base: './',
  define: {
    global: "window",
  },
  build: {
    cssCodeSplit: false,
    minify: true,
    outDir: '../web/build',
  },
  optimizeDeps: {
    esbuildOptions: {
      mainFields: ["module", "main"],
      resolveExtensions: [".js", ".jsx"],
    },
  },
  server: {
    port: 3000,
    open: true,
  },
});
