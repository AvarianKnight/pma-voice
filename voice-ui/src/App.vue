<template>
	<body>
		<audio id="audio_on" src="mic_click_on.ogg"></audio>
		<audio id="audio_off" src="mic_click_off.ogg"></audio>
		<div class="voiceInfo">
			<p v-if="voice.callInfo !== 0" :class="{ talking: voice.talking }">
				[Call]
			</p>
			<p v-if="voice.radioEnabled && voice.radioChannel !== 0" :class="{ talking: voice.usingRadio }">
				{{ voice.radioChannel }} Mhz [Radio]
			</p>
			<p v-if="voice.voiceModes.length" :class="{ talking: voice.talking }">
				{{ voice.voiceModes[voice.voiceMode][1] }} [Range]
			</p>
		</div>
	</body>
</template>

<script>
import { reactive } from "vue";
export default {
	name: "App",
	setup() {
		const voice = reactive({
			voiceModes: [],
			voiceMode: 0,
			radioChannel: 0,
			radioEnabled: false,
			usingRadio: false,
			callInfo: 0,
			talking: false,
		});

		// stops from toggling voice at the end of talking
		let usingUpdated = false
		window.addEventListener("message", function(event) {
			const data = event.data;

			if (data.voiceModes !== undefined) {
				voice.voiceModes = JSON.parse(data.voiceModes);
			}

			if (data.voiceMode !== undefined) {
				voice.voiceMode = data.voiceMode;
			}

			if (data.radioChannel !== undefined) {
				voice.radioChannel = data.radioChannel;
			}

			if (data.radioEnabled !== undefined) {
				voice.radioEnabled = data.radioEnabled;
			}

			if (data.callInfo !== undefined) {
				voice.callInfo = data.callInfo;
			}

			if (data.usingRadio !== voice.usingRadio) {
				usingUpdated = true
				voice.usingRadio = data.usingRadio
				setTimeout(function(){
					usingUpdated = false
				}, 100)
			}
			
			if ((data.talking !== undefined) && !voice.usingRadio && !usingUpdated){
				voice.talking = data.talking
			}

			if (data.sound && voice.radioEnabled) {
				let click = document.getElementById(data.sound);
				// discard these errors as its usually just a 'uncaught promise' from two clicks happening too fast.
				click.load();
				click.volume = data.volume;
				click.play().catch((e) => {});
			}
		});

		return { voice };
	},
};
</script>

<style>
.voiceInfo {
	font-family: Avenir, Helvetica, Arial, sans-serif;
	position: fixed;
	text-align: right;
	bottom: 5px;
	padding: 0;
	right: 5px;
	font-size: 12px;
	font-weight: bold;
	color: rgb(148, 150, 151);
	/* https://stackoverflow.com/questions/4772906/css-is-it-possible-to-add-a-black-outline-around-each-character-in-text */
	text-shadow: 1.25px 0 0 #000, 0 -1.25px 0 #000, 0 1.25px 0 #000,
		-1.25px 0 0 #000;
}
.talking {
	color: rgba(255, 255, 255, 0.822);
}
p {
	margin: 0;
}
</style>
