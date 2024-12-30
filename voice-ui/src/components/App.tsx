import React, { useEffect, useState } from 'react';
import { debugData } from '../utils/debugData';
import { fetchNui } from '../utils/fetchNui';
import { useNuiEvent } from '../hooks/useNuiEvent';
import List from './List';

debugData([
    {
        action: "Debug",
        data: true,
    },
]);

interface Voice {
    voiceModes: Array<[number, string]>;
    voiceMode: number;
    radioChannel: number;
    radioEnabled: boolean;
    usingRadio: boolean;
    callInfo: number;
    talking: boolean;
}

let EnableUI = ""

const App: React.FC = () => {
    const [debug, setDebug] = useState(false);
    const [RadioList, setRadioList] = useState<{ id: string, Name: string, Talking: boolean }[]>([]);
    const [voice, setVoice] = useState<Voice>({
        voiceModes: [],
        voiceMode: 0,
        radioChannel: 0,
        radioEnabled: true,
        usingRadio: false,
        callInfo: 0,
        talking: false,
    });

    useNuiEvent("Debug", (data: string) => {
        setDebug(true);
        EnableUI = 'true'
        setVoice((prevVoice) => ({
            ...prevVoice,
            radioChannel: 1,
            radioEnabled: true,
        }));
    });

    useEffect(() => {
        const handleMessage = (event: MessageEvent) => {
            const data = event.data;
            setVoice((prevVoice) => ({
                ...prevVoice,
                voiceModes: data.voiceModes !== undefined ? [...JSON.parse(data.voiceModes), [0.0, "Custom"]] : prevVoice.voiceModes,
                voiceMode: data.voiceMode !== undefined ? data.voiceMode : prevVoice.voiceMode,
                radioChannel: data.radioChannel !== undefined ? data.radioChannel : prevVoice.radioChannel,
                radioEnabled: data.radioEnabled !== undefined ? data.radioEnabled : prevVoice.radioEnabled,
                callInfo: data.callInfo !== undefined ? data.callInfo : prevVoice.callInfo,
                usingRadio: data.usingRadio !== undefined ? data.usingRadio : prevVoice.usingRadio,
                talking: data.talking !== undefined ? data.talking : prevVoice.talking,
            }));
            if (data.sound) {
                const click = document.getElementById(data.sound) as HTMLAudioElement;
                if (click) {
                    click.load();
                    if (data.volume !== undefined) {
                        click.volume = data.volume;
                    }
                    click.play()
                }
            }
            if (EnableUI === "") {
                EnableUI = data.uiEnabled
            }
        };

        window.addEventListener("message", handleMessage);
        fetchNui("uiReady", {});

        const fetchRadioList = () => {
            if (voice.radioEnabled && voice.radioChannel !== 0) {
                fetchNui("radiolist", {}, [
                    {id: 1, Name: "Player 1", Talking: true},
                    {id: 2, Name: "Player 2", Talking: false},
                ]).then((data: any) => {
                    if (Array.isArray(data)) {
                        setRadioList(data);
                    }
                });
            }
        };

        fetchRadioList();
        const intervalId = setInterval(fetchRadioList, 500);

        return () => {
            window.removeEventListener("message", handleMessage);
            clearInterval(intervalId);
        };
    }, [voice.radioEnabled, voice.radioChannel]);

    return (
        <div>
            <div style={{ visibility: (EnableUI == "true" || EnableUI == "radio") ? "visible" : "hidden" }}>
                {voice.radioEnabled && voice.radioChannel !== 0 && (
                    <List radioList={RadioList} />
                )}
            </div>
            <div style={{ visibility: EnableUI == "true" ? "visible" : "hidden" }} className="fixed bottom-[5px] right-[5px] text-right text-gray-pma text-[0.75rem] font-bold text-shadow-black">
                {debug && <p>Noraml [RANGE]</p>}
                {voice.callInfo !== 0 && (
                    <p className={`${voice.talking ? "text-gray-talking" : ""} transition-colors duration-300`}>
                        [Call]
                    </p>
                )}
                {voice.radioEnabled && voice.radioChannel !== 0 && (
                    <p className={`${voice.usingRadio ? "text-gray-talking" : ""} transition-colors duration-300`}>
                        {voice.radioChannel} Mhz [Radio]
                    </p>
                )}
                {voice.voiceModes.length > 0 && (
                    <p className={`${!voice.usingRadio && voice.talking ? "text-gray-talking" : ""} transition-colors duration-300`}>
                        {voice.voiceModes[voice.voiceMode][1]} [Range]
                    </p>
                )}
            </div>
            <audio id="audio_on" src="sounds/mic_click_on.ogg" preload="auto" />
            <audio id="audio_off" src="sounds/mic_click_off.ogg" preload="auto" />
        </div>
    );
};

export default App;