'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const { getSecureSystemPrompt } = require('./prompts');

test('interactive chat receives cautious Arabic dialect adaptation', () => {
  for (const mode of ['chat', 'analyze']) {
    const prompt = getSecureSystemPrompt(mode, {}, 'friend');
    assert.match(prompt, /ARABIC DIALECT ADAPTATION/);
    assert.match(prompt, /clear, recurring wording/);
    assert.match(prompt, /Never infer it from the app locale/);
    assert.match(prompt, /Never announce, explain, or expose/);
    assert.match(prompt, /her broad home country\/region, or her preferred dialect/);
    assert.match(prompt, /Never store a precise\/live location/);
  }
});

test('structured and specialised prompts do not receive dialect rules', () => {
  for (const mode of ['doctor', 'briefing', 'emergency', 'mood']) {
    const prompt = getSecureSystemPrompt(mode, {}, 'friend');
    assert.doesNotMatch(prompt, /ARABIC DIALECT ADAPTATION/);
  }
});
