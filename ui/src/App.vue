<template>
	<body>
		<audio id="audio_on" src="mic_click_on.ogg"></audio>
		<audio id="audio_off" src="mic_click_off.ogg"></audio>
		<div v-if="voice.uiEnabled" class="voiceInfo">
			<p v-if="voice.callInfo !== 0" :class="{ talking: voice.talking && !voice.usingRadio }">
				[Call]
			</p>
			<p v-if="voice.radioEnabled && voice.radioChannel !== 0" 
			   :class="{ 
			     talking: voice.usingRadio && voice.currentActiveRadio === 'primary', 
			     active: voice.currentActiveRadio === 'primary' && !voice.usingRadio
			   }">
				{{ voice.radioChannel }} MHz [Primary Radio]
			</p>
			<p v-if="voice.radioEnabled && voice.secondaryRadioChannel !== 0" 
			   :class="{ 
			     talking: voice.usingRadio && voice.currentActiveRadio === 'secondary', 
			     active: voice.currentActiveRadio === 'secondary' && !voice.usingRadio
			   }">
				{{ voice.secondaryRadioChannel }} MHz [Secondary Radio]
			</p>
			<p v-if="voice.voiceModes.length" :class="{ talking: voice.talking && !voice.usingRadio }">
				{{ voice.voiceModes[voice.voiceMode][1] }} [Range]
			</p>
		</div>
	</body>
</template>

<script setup lang="ts">
import { reactive, onMounted } from "vue";

interface VoiceState {
	uiEnabled: boolean;
	voiceModes: [number, string][];
	voiceMode: number;
	radioChannel: number;
	secondaryRadioChannel: number;
	radioEnabled: boolean;
	usingRadio: boolean;
	currentActiveRadio: string;
	callInfo: number;
	talking: boolean;
}

const voice = reactive<VoiceState>({
	uiEnabled: true,
	voiceModes: [],
	voiceMode: 0,
	radioChannel: 0,
	secondaryRadioChannel: 0,
	radioEnabled: true,
	usingRadio: false,
	currentActiveRadio: "primary",
	callInfo: 0,
	talking: false,
});

function handleMessage(event: MessageEvent) {
	const data = event.data;

	if (data.uiEnabled !== undefined) {
		voice.uiEnabled = data.uiEnabled;
	}

	if (data.voiceModes !== undefined) {
		voice.voiceModes = JSON.parse(data.voiceModes);
		// Push our own custom type for modes that have their range changed
		let voiceModes = [...voice.voiceModes];
		voiceModes.push([0.0, "Custom"]);
		voice.voiceModes = voiceModes;
	}

	if (data.voiceMode !== undefined) {
		voice.voiceMode = data.voiceMode;
	}

	if (data.radioChannel !== undefined) {
		voice.radioChannel = data.radioChannel;
	}

	if (data.secondaryRadioChannel !== undefined) {
		voice.secondaryRadioChannel = data.secondaryRadioChannel;
	}

	if (data.currentActiveRadio !== undefined) {
		voice.currentActiveRadio = data.currentActiveRadio;
	}

	if (data.radioEnabled !== undefined) {
		voice.radioEnabled = data.radioEnabled;
	}

	if (data.callInfo !== undefined) {
		voice.callInfo = data.callInfo;
	}

	if (data.usingRadio !== undefined) {
		voice.usingRadio = data.usingRadio;
	}
	
	if (data.talking !== undefined) {
		voice.talking = data.talking;
	}

	if (data.sound && voice.radioEnabled && (voice.radioChannel !== 0 || voice.secondaryRadioChannel !== 0)) {
		let click = document.getElementById(data.sound) as HTMLAudioElement;
		if (click) {
			// discard these errors as its usually just a 'uncaught promise' from two clicks happening too fast.
			click.load();
			click.volume = data.volume;
			click.play().catch(() => {});
		}
	}
}

onMounted(() => {
	window.addEventListener("message", handleMessage);
	
	fetch(`https://${(window as any).GetParentResourceName()}/uiReady`, { method: 'POST' });
});
</script>