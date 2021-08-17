(
/*


/////////////////////////////////
// Johnny V2.5: -- 17.08.2021. //
/////////////////////////////////

Listen port forced to 57120.

NEW : Change the Guitare logic for "Que je t'aime".

NOTE:

Le tune va de 0.9 a 1.1.
1 est l'accordage de base.

En cliquant sur la fenetre Tune et en appuyant sur Alt + up/donw tu as un fine range...

*/


{

	s.waitForBoot{

		//------------------------ Global script variables && init --------------------//

		var switch, fadeTime, hero, feedEnd, seq, seq2, moto, moto2,
		sounds, guitare_seqDown, guitare_seqUp, relative_path, cater,
		osculator_path, qlab_path, folder, osc_out, btn_clbck, sampler_sounds, sampler_sounds_loop;

		var guitarNotes, synthGuitare, guit, fineTune;
		var tunWindow, potTune, panicWindow, panicButton;

		var pitch = Bus.control(s, 1);
		var accel = Bus.control(s, 1);
		var whammy = Bus.control(s, 1);

		//Control attribut function => OSCFunc.
		var setSynthFreq = { |id, value|
			pitch.setAt(id, value);
		};

		var ffreq = { |id, value|
			accel.setAt(id, value);
		};

		var freqs = { |id, value|
			whammy.setAt(id, value);
		};

		//Check Network port to prevent Port error and force to 57120.
		var port_cheker = {
			var port = NetAddr.langPort;
			if (port != 57120, { thisProcess.openUDPPort(57120) });
			("\n'Johnny forever'!!\n\n").postln;
			("SuperCollider opened port(s):"+thisProcess.openPorts).postln;
			osc_out = NetAddr("127.0.0.1", 8000);
		}.value;

		//------------------------------ GUI General -----------------------------------//

		var wind = Window.closeAll;
		var volume = s.volume.gui;
		s.meter;

		//----------------------------- GUI Tune Pot -----------------------------------//

		tunWindow = Window("Tune", Rect(1325, 200, 150, 150), resizable: false)
		.front;

		potTune = Knob(tunWindow, Rect(15, 10, 120, 120))
		.value_(0.5)
		.mode_(\vert)
		.centered_(true)
		.action_({
			|obj|
			var tune;
			tune = obj.value.linlin(0.0, 1.0, 0.9, 1.1).postln;
			fineTune = tune;
		});

		//---------------------------- GUI Panic Button -------------------------------//

		panicWindow = Window("PANIC!!", Rect(1500, 50, 300, 300))
		.front.alpha_(0.89);

		panicButton = Button(panicWindow, Rect(0, 0, 300, 300))
		.states_([
			["!", Color.black, Color.red],
			["!", Color.black, Color.red]
		]);

		panicButton.font_(Font(size: 120));

		panicButton.action_({ |view|
			if (view.value == 1, {
				s.defaultGroup.set(\gate, 0, \fadeTime, 0.05);
			});
		});

		//////////////////// Init the fine tune for guitare_melodieUp. //////////////////
		fineTune = 1;
		/////////////////////////////////////////////////////////////////////////////////

		//--------------------------------- Init Script -------------------------------//

		sounds = Array.new;
		relative_path = "".resolveRelative;

		osculator_path = relative_path+/+"johnny_osc.osc3";
		osculator_path.openOS;

		folder = PathName(relative_path+/+"soundfiles");
		folder.entries.do({ |path|
			sounds = sounds.add(Buffer.readChannel(s, path.fullPath, channels: 0));
		});

		OSCdef(\guitare_melodieUp).disable; "Locked".postln;

		btn_clbck = { |nb=2|
			Routine({
				nb.do{
					osc_out.sendMsg("/vibrate", 1); 0.1.wait;
					osc_out.sendMsg("/vibrate", 0); 0.2.wait;
				};
			}).play;
		};

		//--------------------------------- SynthDefs -------------------------------//

		SynthDef(\player_tuned, { |pan=0, amp=0.5, buf, rate=1, loop=0, gate=0, rel=1|
			var sig, mix, env;
			env = EnvGen.kr(Env.asr(0.01, 1, rel), gate, doneAction:2);
			sig = PlayBuf.ar(buf.numChannels, buf, BufRateScale.kr(buf) * rate, loop: loop, doneAction:2);
			sig  = sig * env;

			if (buf.numChannels == 1, {
				sig = Pan2.ar(sig, pos: pan, level: amp.lag(0.05));
			}, {
				sig = Splay.ar(sig, level: amp.lag(0.05), center: pan);
			});

			Out.ar(0, Pan2.ar(sig, pan, amp));
		}).add;

		SynthDef(\caterpilard, { |amp=0.5, gate=1, out|
			var sig, car, env;
			env = EnvGen.kr(Env.asr(7, 1, 7), gate, doneAction:2);
			sig = SinOsc.ar([25, 30] + SinOsc.ar(65, mul: 35), mul:amp);
			sig = sig * env * amp;
			Out.ar(out, Splay.ar(sig, center: SinOsc.kr(0.05).range(-1, 1)));
		}).add;

		SynthDef(\hardRock, { |out, gate=1, pan=0, freq=300, amp=0.07, noiselevel=0.2,
			minfreq=100, decaytime=1, doneAction=2, ffreq=500, rq=0.3, spread=0.8|
			var sig, env;
			sig = WhiteNoise.ar(noiselevel);
			sig = sig + ClipNoise.ar(noiselevel);
			sig = sig + AllpassC.ar(sig, 1/minfreq, 1/freq, decaytime);
			sig = RLPF.ar(sig, ffreq * \ffreqtab.kr(1!10), rq);
			env = EnvGen.kr(\adsr.kr(Env.adsr(0.6,0.1,0.8,0.1)), gate, doneAction:doneAction);
			sig = sig * env;
			sig = Splay.ar(sig, spread, 1, pan);
			sig = sig * amp;
			Out.ar(out,sig);
		}).add;

		SynthDef(\feedEnd, { |amp=1|
			var snd, string, delay, env;
			string = { |freq|
				var delay;
				delay = freq.reciprocal;
				Pluck.ar(SinOsc.ar(Line.ar(1000, 50, 0.01)) * Env.perc(0.001, 0.01).ar,
					Impulse.ar(0), delay, delay, 5, 0.5)};

			env = EnvGen.kr(Env.linen(0.01, releaseTime: 10), doneAction:2);
			snd = string.(100) + string.(150) + string.(200);
			snd = snd + (HPF.ar(LocalIn.ar(1), 3000) * -50.dbamp);
			snd = (snd * 32.dbamp).tanh;
			snd = RLPF.ar(snd, 3000, 0.5);
			snd = (snd * 32.dbamp).tanh;
			snd = RLPF.ar(snd, 500, 0.5);
			snd = (snd * 32.dbamp).tanh;
			snd = BHiShelf.ar(snd, 3200, 1, -3.0);
			snd = LeakDC.ar(snd);
			LocalOut.ar(snd);
			snd = DelayC.ar(snd, 0.1, SinOsc.kr(2, [0, 1pi]).range(0, 1e-4));
			snd = snd * env;
			Out.ar(0, snd * amp);
		}).add;

		SynthDef(\player_mono, { |pan=0, amp=0.5, buf, rate=1, loop=0|
			var sig, mix;
			sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, loop: loop, doneAction:2);
			Out.ar(0, Pan2.ar(sig, pan, amp));
		}).add;

		hero = Ndef(\feedback_hero, { |delFreq = 20|
			var sig = Ndef(\feedback_hero).ar + WhiteNoise.ar(0.001 !2);
			var a, k, delfreq, minfreqs, freqs, dry;
			delfreq = delFreq;
			sig = DelayN.ar(sig, 1 / 10 - ControlDur.ir, 1 / delfreq - ControlDur.ir);
			freqs = (64 + [0,5, 10, 15, 19, 24]).midicps / 8;
			minfreqs = freqs * 0.5;
			freqs = freqs * whammy.kr.linlin(0, 0.5, 1, 0.75).lag(4);
			sig = CombN.ar(sig ! 6,1 / minfreqs, 1 / freqs, 8).mean;
			sig = LPF.ar(sig, 8000);
			sig = HPF.ar(sig * pitch.kr.linlin(0, 1, 0, 7).varlag(0.05), 80);
			sig = RLPFD.ar(sig, accel.kr.linexp(0.2, 0.55, 800, 10000).lag(0.2) * [1, 1.1], 0.1, 0.5);
			sig = sig + sig.mean;
			dry = sig;
			10.do {
				d = 0.2.rand;
				sig = AllpassN.ar(sig, d, d, 5);
			};
			(dry + sig) * 0.1;
		}).add;

		s.sync;

		//init after synthdefs.
		switch = 0;
		hero.fadeTime = 5;
		seq = Pseq(#[48, 52, 40], inf).asStream; // ICI NOTES Guitare DOWN.

		guitarNotes = 0;
		synthGuitare = [];

		//--------------------------------- ODC Controls -------------------------------//

		OSCdef(\guitare_melodieDown, { |msg|
			if (msg[1] == 1, {
				Routine({
					var pbind = Pbind(\instrument, \hardRock,
						\midinote, seq.next,
						\octave, Pstep(Pseq([3,4],inf),Pseq([5,0.75],inf)),
						\minfreq, 50,
						\decaytime, 1.0,
						\adsr, Pseq([
							[Env.adsr(0.02,0.1,0.8,1.6,curve:0.5)],
							[Env.adsr(0.02,0.1,0.8,1.6,curve:0.5)],
							[Env.adsr(0.02,0.1,0.8,1.6,curve:0.5)],
							[Env.adsr(0.03,0.1,0.8,1.6,curve:0.7)],
							[Env.adsr(0.03,0.1,0.8,1.8,curve:0.7)],
							[Env.adsr(0.03,0.1,0.8,1.10,curve:0.7)],
						],inf),
						\legato, 1.0,
						\ffreq, [500,610,820,140],
						\ffreqtab, [ 6, 4, 5, 10, 1, 1.2, 0.8, 1.1, 2, 8],
						\dur, Pseq([4],inf),
						\spread, 0.5,
						\amp, 1.6
					).play;
					0.1.wait; pbind.stop;
				}).play;
			});
		}, "/stringDown"
		);

		OSCdef(\guitare_melodieUp, { |msg|
			if (msg[1] == 1, {

				case

				{ guitarNotes == 0 } {

					if (synthGuitare.isPlaying, {synthGuitare.release(0.5)});

					synthGuitare = Synth(\player_tuned, [\buf, sounds[5], \gate, 1, \rate, fineTune]).register;
					guitarNotes = guitarNotes + 1;
				}

				{ guitarNotes == 1 } {

					if (synthGuitare.isPlaying, {synthGuitare.release(0.5)});

					synthGuitare = Synth(\player_tuned, [\buf, sounds[5], \gate, 1, \rate, fineTune]).register;
					guitarNotes = guitarNotes + 1;
				}

				{ guitarNotes == 2 } {

					if (synthGuitare.isPlaying, {synthGuitare.release(0.5)});

					synthGuitare = Synth(\player_tuned, [\buf, sounds[6], \gate, 1, \rate, fineTune]).register;
					guitarNotes = guitarNotes + 1;
				}

				{ guitarNotes == 3 } {

					if (synthGuitare.isPlaying, {synthGuitare.release(0.5)});

					synthGuitare = Synth(\player_tuned, [\buf, sounds[7], \gate, 1, \rate, fineTune]).register;
					guitarNotes = 0;
				}

			});

		}, "/stringUp"
		);

		OSCdef(\guitare_feedback_switch, { |msg|
			var synth;

			case

			{msg[1] == 1 && hero.isPlaying && (switch == 0)} {hero.play; switch = 1; btn_clbck.value(1)}
			{msg[1] == 1 && hero.isPlaying.not && (switch == 1 && (e.isPlaying.not))} {hero.play; btn_clbck.value(1)}
			{msg[1] == 1 && hero.isPlaying && (switch == 1 && (e.isPlaying.not))} {
				hero.end;
				btn_clbck.value(6);
				e = Synth(\feedEnd, [\amp, 0]).register;
			};
		}, "/k5"
		);

		OSCdef(\one_shot_sample, { |msg|
			if (msg[1] == 1 && (sampler_sounds.isPlaying.not), {
				sampler_sounds = Synth(\player_mono, [\buf, sounds[0], \amp, 1, \pan, 0.0]).register;
			});
		}, "/b1"
		);

		OSCdef(\one_shot_sampleBeep, { |msg|
			if (msg[1] == 1 && (sampler_sounds_loop.isPlaying.not), {
				sampler_sounds_loop = Synth(
					\player_mono, [\buf, sounds[2], \amp, 1.5, \pan, 0.0, \loop, 1]).register;
			});

			if (msg[1] == 0 && (sampler_sounds_loop.isPlaying), {sampler_sounds_loop.free});
		}, "/up"
		);

		OSCdef(\feedEnd, { |msg|
			if (msg[1] == 1 && (u.isPlaying.not), {
				u = Synth(\feedEnd, [\amp, 0.25]).register;
			});
		}, "/k4"
		);

		OSCdef(\k3, { |msg|
			if (msg[1] == 1 && (moto.isPlaying.not), {
				moto = Synth(\player_mono, [\buf, sounds[4], \amp, 1.5]).register
			});

			if (msg[1] == 1 && (moto.isPlaying), {
				moto2 = Synth(\player_mono, [\buf, sounds[3], \amp, 1.5]).register
			});
		}, "/k3"
		);

		OSCdef(\caterP, {|msg|
			if(msg[1] == 1 && (cater.isPlaying.not), {
				cater = Synth(\caterpilard, [\amp, 0.5]).register;
			});

			if (msg[1] == 1 && (cater.isPlaying), {
				cater.release(5);
			});
		}, "/cater"
		);

		//OSCFunc for ControlBus.
		OSCFunc.new( { |msg| freqs.value(msg[1], msg[1]) },'/whammy');

		OSCFunc.new( { |msg| setSynthFreq.value(msg[1], msg[1]) }, '/pry');

		OSCFunc.new( { |msg| ffreq.value(msg[4], msg[4]) }, '/pry');

		//Locker for Sequencer in the end.
		OSCdef(\Qlab, { |msg|
			if (msg[1] == 1, {
				OSCdef(\guitare_melodieUp).disable;
				"Locked".postln;
			});

			if (msg[1] == 0, {
				OSCdef(\guitare_melodieUp).enable;
				"Unloked".postln;
			});
		}, "/lock"
		);

	};

}.fork
)
