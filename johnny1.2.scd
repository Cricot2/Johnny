
(
/*


          JJJJJJJJJJJ              hhhhhhh
          J:::::::::J              h:::::h
          J:::::::::J              h:::::h
          JJ:::::::JJ              h:::::h
            J:::::J   ooooooooooo   h::::h hhhhh      nnnn  nnnnnnnn    nnnn  nnnnnnnn yyyyyyy           yyyyyyy
            J:::::J oo:::::::::::oo h::::hh:::::hhh   n:::nn::::::::nn  n:::nn::::::::nny:::::y         y:::::y
            J:::::Jo:::::::::::::::oh::::::::::::::hh n::::::::::::::nn n::::::::::::::nny:::::y       y:::::y
            J:::::jo:::::ooooo:::::oh:::::::hhh::::::hnn:::::::::::::::nnn:::::::::::::::ny:::::y     y:::::y
            J:::::Jo::::o     o::::oh::::::h   h::::::h n:::::nnnn:::::n  n:::::nnnn:::::n y:::::y   y:::::y
JJJJJJJ     J:::::Jo::::o     o::::oh:::::h     h:::::h n::::n    n::::n  n::::n    n::::n  y:::::y y:::::y
J:::::J     J:::::Jo::::o     o::::oh:::::h     h:::::h n::::n    n::::n  n::::n    n::::n   y:::::y:::::y
J::::::J   J::::::Jo::::o     o::::oh:::::h     h:::::h n::::n    n::::n  n::::n    n::::n    y:::::::::y
J:::::::JJJ:::::::Jo:::::ooooo:::::oh:::::h     h:::::h n::::n    n::::n  n::::n    n::::n     y:::::::y
 JJ:::::::::::::JJ o:::::::::::::::oh:::::h     h:::::h n::::n    n::::n  n::::n    n::::n      y:::::y
   JJ:::::::::JJ    oo:::::::::::oo h:::::h     h:::::h n::::n    n::::n  n::::n    n::::n     y:::::y
     JJJJJJJJJ        ooooooooooo   hhhhhhh     hhhhhhh nnnnnn    nnnnnn  nnnnnn    nnnnnn    y:::::y
                                                                                             y:::::y
                                                                                            y:::::y
                                                                                           y:::::y
                                                                                          y:::::y
                                                                                         yyyyyyy


Johnny V1.2: -- 13.11.2020.

TODO:

-Mettre à jour Max...
-MouseBouton.kr => Wii Mapping.
-Add Prevent bad audio routing => default MacBoock.
-Add s.meter.alwaysOnTop_(true);
-C'est quoi la commande pour allumer le BT automatiquement?
- x = Synth... Globals variables change.

FIXME:

-Bug in script compilation, ~iter go in loop? => Must wait befor init.
-"Already playing" error message

*/


{
	s.waitForBoot{

		//Globals variables.
		var switch, fadeTime, hero, feedEnd, event, sounds,
		relative_path, osculator_path, folder, osculator_input;

		//Control Bus.
		var pitch = Bus.control(s, 1);
		var accel = Bus.control(s, 1);
		var vibrato = Bus.control(s, 1);

		//Control attribut function => OSCFunc.
		var setSynthFreq = { |id, value|
			pitch.setAt(id, value);
		};

		var ffreq = { |id, value|
			accel.setAt(id, value);
		};

		//Check Network port to prevent Port error.
		var port_cheker = {
			var n_port, str_ok;
			var port = NetAddr.langPort;
			if (port != 57120, {
				">>> Attention le port 57120 n'est pas disponible!".postln;
				n_port = ">>> Veuillez mettre le port d'OSCulator sur"+port;
				n_port.postln;
				">>> Puis essayez de lancer un son depuis le controleur.".postln;
			},{
				str_ok = ">>> SuperCollider écoute bien sur le bon port:"+port++"."; str_ok.postln;
				"\n>>> Attendez qq secondes qu'il n'y ai plus aucun son!! \n>>> Puis faire un test avec la Wii.".postln;
			});

		}.value;

		//Initialise root folder directorie for soundfiles and open OSCulator.
		sounds = Array.new;
		relative_path = resolveRelative("");

		osculator_path = relative_path+/+"johnny_osc.osc3";
		osculator_path.openOS;

		folder = PathName(relative_path+/+"soundfiles");
		folder.entries.do({
			arg path;
			sounds = sounds.add(Buffer.read(s, path.fullPath));
		});

		osculator_input = NetAddr("127.0.0.1", 8000);

		("\n'Johnny forever'!!\n\n").postln;

		SynthDef(\hardRock, { arg out, gate=1, pan=0, freq=300, amp=0.1, noiselevel=0.2,
			minfreq=100, decaytime=1, doneAction=2, ffreq=500, rq=0.3, spread=0.8;
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
		}).store;

		SynthDef(\player_mono, {
			|pan=0, amp=0.5, buf, rate=1|
			var sig, mix;
			sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, doneAction:2);
			Out.ar(0, Pan2.ar(sig, pan, amp));
		}).add;

		hero = Ndef(\feedback_hero, {
			|delFreq = 20|
			var sig = Ndef(\feedback_hero).ar + WhiteNoise.ar(0.001 !2);
			var a, k, delfreq, minfreqs, freqs, dry;
			delfreq = delFreq;
			sig = DelayN.ar(sig, 1 / 10 - ControlDur.ir, 1 / delfreq - ControlDur.ir);
			freqs = (64 + [0,5, 10, 15, 19, 24]).midicps / 8;
			minfreqs = freqs * 0.5;
			freqs = freqs * MouseButton.kr(1,0.75,4);
			sig = CombN.ar(sig ! 6,1 / minfreqs, 1 / freqs, 8).mean;
			sig = LPF.ar(sig, 8000);
			sig = HPF.ar(sig * pitch.kr.linlin(0, 1, 0, 5), 80);
			sig = RLPFD.ar(sig, accel.kr.linlin(0, 1, 200, 10000) * [1, 1.1], 0.1, 0.5);
			sig = sig + sig.mean;
			dry = sig;
			10.do {
				d = 0.2.rand;
				sig = AllpassN.ar(sig, d, d, 5);
			};
			(dry + sig) * 0.120;
		}).add;

		//A function launch in feedback_hero end.
		feedEnd = {
			var snd, string, delay, env;
			string = {
				|freq|
				var delay;
				delay = freq.reciprocal;
				Pluck.ar(SinOsc.ar(Line.ar(1000, 50, 0.01)) * Env.perc(0.001, 0.01).ar,
					Impulse.ar(0), delay, delay, 5, 0.5)};

			env = EnvGen.kr(Env.linen(0.01, releaseTime: 10, level: -13.dbamp), doneAction:2);
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
		};

		s.sync;

		//init.
		switch = 0;
		fadeTime = 5;
		hero.fadeTime = fadeTime / 2;

		//Pbind to control \hardRock synth and play next note with string button.
		event = (
			fork{
				var seq = Pbind(\x, Pseq([1, 2, 3], inf),
					\instrument, \hardRock,
					\midinote, Pseq([48, 52, 40], inf),
					\octave, Pstep(Pseq([3,4],inf),Pseq([5,0.75],inf)),
					\minfreq, 50,
					\decaytime, 1.0,
					\adsr, Pseq([
						[Env.adsr(0.02,0.1,0.8,0.4,curve:0.5)],
						[Env.adsr(0.02,0.1,0.8,0.4,curve:0.5)],
						[Env.adsr(0.02,0.1,0.8,0.4,curve:0.5)],
						[Env.adsr(0.03,0.1,0.8,0.6,curve:0.7)],
						[Env.adsr(0.03,0.1,0.8,0.6,curve:0.7)],
						[Env.adsr(0.03,0.1,0.8,0.6,curve:0.7)],
					],inf),
					\ffreq, [500,610,820,140],
					\ffreqtab, [ 6, 4, 5, 10, 1, 1.2, 0.8, 1.1, 2, 8  ],
					\dur, Pseq([6],inf),
					\spread, 0.1,
					\amp, 1.7
				).play;

				x = seq.asStream;
				0.5.wait;
				x.stop;
			});

		//OSC MAP.
		OSCdef(\guitare_feedback_switch, {
			|msg|
			if (msg[1] == 1 && {switch == 0}, {

				fork{
					0.1.wait;
					hero.play;
					hero.fadeTime = fadeTime;
					switch = 1;
				}
			});

			//With Wii rumble callback.
			if (msg[1] == 1 && {switch == 1}, {

				hero.end;

				fork{
					feedEnd.play;
					osculator_input.sendMsg("/vibrate", 1);
					5.wait;
					switch = 0;
					5.wait;
					osculator_input.sendMsg("/vibrate", 0);
				}

			});
		}, "/b2"
		);

		OSCdef(\one_shot_sample, {
			|msg|
			if (msg[1] == 1 && (~sampler_sounds.isPlaying.not), {
				~sampler_sounds = Synth(\player_mono, [\buf, sounds[0], \amp, 0.9, \pan, 0.0]).register;
			});
		}, "/b1"
		);

		OSCdef(\guitare_melodie, {
			|msg|
			if (msg[1] == 1, {
				x.next((x.play));
			});
		}, "/down"  // '/string' pour wii guitare.
		);

		//OSCFunc for ControlBus.
		OSCFunc.new({
			|msg|
			//linlin map pitch.
			setSynthFreq.value(msg[1], msg[1])
		}, '/pry'
		);

		OSCFunc.new({
			|msg|
			//linlin map accel.
			ffreq.value(msg[4], msg[4])
		}, '/pry'
		)
	};

}.fork
)
