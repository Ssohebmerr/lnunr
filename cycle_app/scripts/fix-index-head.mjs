import fs from 'fs';
import path from 'path';

const file = path.resolve('public/index.html');
let html = fs.readFileSync(file, 'utf8');

html = html.replace(
  /<link rel="stylesheet" href="site\.css" \/>\s*<style>[\s\S]*?<\/style>/,
  `<link rel="stylesheet" href="site.css" />\n<link rel="stylesheet" href="home.css" />`
);

fs.writeFileSync(file, html);
console.log('index.html head updated');
