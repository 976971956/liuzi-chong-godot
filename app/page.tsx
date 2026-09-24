'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

type Player = 'red' | 'blue';
type Cell = Player | null;
type BoardSkin = 'wood' | 'jade' | 'night' | 'paper';
type PieceSkin = 'classic' | 'glass' | 'stone' | 'flat';
type MusicTrack = 'mountain' | 'rain' | 'moon';

type Snapshot = {
  board: Cell[];
  current: Player;
  winner: Player | null;
  status: string;
  moveCount: number;
  lastMove: number | null;
};

const ROWS = 5;
const COLS = 4;

const BOARD_SKINS: { id: BoardSkin; label: string }[] = [
  { id: 'wood', label: '古木' },
  { id: 'jade', label: '青玉' },
  { id: 'night', label: '星夜' },
  { id: 'paper', label: '宣纸' },
];

const PIECE_SKINS: { id: PieceSkin; label: string }[] = [
  { id: 'classic', label: '篆刻' },
  { id: 'glass', label: '琉璃' },
  { id: 'stone', label: '卵石' },
  { id: 'flat', label: '极简' },
];

const MUSIC_TRACKS: { id: MusicTrack; label: string; pattern: number[]; bass: number; tempo: number }[] = [
  { id: 'mountain', label: '溪山清韵', pattern: [392, 440, 523.25, 587.33, 659.25, 587.33, 523.25, 440], bass: 196, tempo: 1380 },
  { id: 'rain', label: '竹窗夜雨', pattern: [261.63, 293.66, 392, 440, 523.25, 440, 392, 293.66], bass: 130.81, tempo: 1120 },
  { id: 'moon', label: '松间明月', pattern: [293.66, 392, 440, 523.25, 587.33, 523.25, 440, 392], bass: 146.83, tempo: 1540 },
];

function makeInitialBoard(): Cell[] {
  const board: Cell[] = Array(ROWS * COLS).fill(null);
  [0, 1, 2, 3, 4, 7].forEach((index) => { board[index] = 'red'; });
  [12, 15, 16, 17, 18, 19].forEach((index) => { board[index] = 'blue'; });
  return board;
}

function coords(index: number) {
  return { row: Math.floor(index / COLS), col: index % COLS };
}

function validMovesFor(index: number, board: Cell[]) {
  const { row, col } = coords(index);
  return [[row - 1, col], [row + 1, col], [row, col - 1], [row, col + 1]]
    .filter(([r, c]) => r >= 0 && r < ROWS && c >= 0 && c < COLS)
    .map(([r, c]) => r * COLS + c)
    .filter((target) => board[target] === null);
}

function captureTargets(board: Cell[], movedIndex: number, player: Player) {
  const opponent: Player = player === 'red' ? 'blue' : 'red';
  const { row, col } = coords(movedIndex);
  const lines = [
    Array.from({ length: COLS }, (_, c) => row * COLS + c),
    Array.from({ length: ROWS }, (_, r) => r * COLS + col),
  ];
  const targets = new Set<number>();

  for (const line of lines) {
    for (let start = 0; start <= line.length - 3; start += 1) {
      const window = line.slice(start, start + 3);
      if (!window.includes(movedIndex)) continue;
      const values = window.map((index) => board[index]);
      const forward = values[0] === player && values[1] === player && values[2] === opponent;
      const backward = values[0] === opponent && values[1] === player && values[2] === player;
      if (!forward && !backward) continue;

      // 采用“活枪”规则：三子之外紧邻处需为空，不能借已有长串重复吃子。
      const before = line[start - 1];
      const after = line[start + 3];
      const cleanBefore = before === undefined || board[before] === null;
      const cleanAfter = after === undefined || board[after] === null;
      if (cleanBefore && cleanAfter) targets.add(forward ? window[2] : window[0]);
    }
  }
  return [...targets];
}

function hasAnyMove(board: Cell[], player: Player) {
  return board.some((cell, index) => cell === player && validMovesFor(index, board).length > 0);
}

export default function Home() {
  const [board, setBoard] = useState<Cell[]>(makeInitialBoard);
  const [current, setCurrent] = useState<Player>('red');
  const [selected, setSelected] = useState<number | null>(null);
  const [winner, setWinner] = useState<Player | null>(null);
  const [status, setStatus] = useState('红方先行，请选择一枚棋子');
  const [history, setHistory] = useState<Snapshot[]>([]);
  const [moveCount, setMoveCount] = useState(0);
  const [lastMove, setLastMove] = useState<number | null>(null);
  const [boardSkin, setBoardSkin] = useState<BoardSkin>('wood');
  const [pieceSkin, setPieceSkin] = useState<PieceSkin>('classic');
  const [musicTrack, setMusicTrack] = useState<MusicTrack>('mountain');
  const [musicOn, setMusicOn] = useState(false);
  const [sfxOn, setSfxOn] = useState(true);
  const [rulesOpen, setRulesOpen] = useState(false);

  const audioRef = useRef<AudioContext | null>(null);
  const musicTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const musicStepRef = useRef(0);

  const ensureAudio = useCallback(() => {
    if (!audioRef.current) audioRef.current = new AudioContext();
    if (audioRef.current.state === 'suspended') void audioRef.current.resume();
    return audioRef.current;
  }, []);

  const tone = useCallback((frequency: number, duration: number, volume: number, type: OscillatorType = 'sine', delay = 0) => {
    const context = ensureAudio();
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    const filter = context.createBiquadFilter();
    const start = context.currentTime + delay;
    oscillator.type = type;
    oscillator.frequency.setValueAtTime(frequency, start);
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(Math.max(900, frequency * 5), start);
    filter.Q.setValueAtTime(.7, start);
    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(volume, start + Math.min(.04, duration * .18));
    gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
    oscillator.connect(filter).connect(gain).connect(context.destination);
    oscillator.start(start);
    oscillator.stop(start + duration + 0.03);
  }, [ensureAudio]);

  const woodTap = useCallback((frequency: number, volume = .08, delay = 0) => {
    const context = ensureAudio();
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    const filter = context.createBiquadFilter();
    const start = context.currentTime + delay;
    oscillator.type = 'triangle';
    oscillator.frequency.setValueAtTime(frequency * 1.55, start);
    oscillator.frequency.exponentialRampToValueAtTime(frequency * .62, start + .13);
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(Math.min(1900, frequency * 5), start);
    filter.Q.setValueAtTime(1.4, start);
    gain.gain.setValueAtTime(.0001, start);
    gain.gain.exponentialRampToValueAtTime(volume, start + .004);
    gain.gain.exponentialRampToValueAtTime(.0001, start + .16);
    oscillator.connect(filter).connect(gain).connect(context.destination);
    oscillator.start(start);
    oscillator.stop(start + .19);
  }, [ensureAudio]);

  const playSfx = useCallback((kind: 'select' | 'move' | 'capture' | 'win') => {
    if (!sfxOn) return;
    if (kind === 'select') {
      tone(659.25, .12, .028, 'triangle');
      tone(987.77, .22, .012, 'sine', .025);
    }
    if (kind === 'move') {
      woodTap(205, .1);
      tone(329.63, .22, .024, 'triangle', .025);
    }
    if (kind === 'capture') {
      woodTap(142, .13);
      tone(196, .28, .038, 'triangle', .045);
      tone(293.66, .34, .022, 'sine', .095);
    }
    if (kind === 'win') {
      [392, 440, 523.25, 659.25, 783.99].forEach((note, index) => {
        woodTap(note / 2, .055, index * .1);
        tone(note, .6, .035, 'sine', index * .1 + .015);
        tone(note * 2, .34, .009, 'triangle', index * .1 + .05);
      });
    }
  }, [sfxOn, tone, woodTap]);

  const stopMusic = useCallback(() => {
    if (musicTimerRef.current) clearInterval(musicTimerRef.current);
    musicTimerRef.current = null;
    musicStepRef.current = 0;
  }, []);

  const startMusic = useCallback((trackId: MusicTrack) => {
    stopMusic();
    ensureAudio();
    const track = MUSIC_TRACKS.find((item) => item.id === trackId) ?? MUSIC_TRACKS[0];
    const playNote = () => {
      const frequency = track.pattern[musicStepRef.current % track.pattern.length];
      const step = musicStepRef.current;
      tone(frequency, 1.16, .016, 'sine');
      tone(frequency * 2, .46, .006, 'triangle', .08);
      if (step % 4 === 0) tone(track.bass, 1.9, .007, 'sine');
      musicStepRef.current += 1;
    };
    playNote();
    musicTimerRef.current = setInterval(playNote, track.tempo);
  }, [ensureAudio, stopMusic, tone]);

  useEffect(() => () => {
    stopMusic();
    if (audioRef.current) void audioRef.current.close();
  }, [stopMusic]);

  const counts = useMemo(() => ({
    red: board.filter((cell) => cell === 'red').length,
    blue: board.filter((cell) => cell === 'blue').length,
  }), [board]);

  const validMoves = useMemo(() => selected === null ? [] : validMovesFor(selected, board), [selected, board]);

  const resetGame = useCallback(() => {
    setBoard(makeInitialBoard());
    setCurrent('red');
    setSelected(null);
    setWinner(null);
    setStatus('新棋局开始，红方先行');
    setHistory([]);
    setMoveCount(0);
    setLastMove(null);
    playSfx('move');
  }, [playSfx]);

  const movePiece = useCallback((from: number, to: number) => {
    setHistory((previous) => [...previous, { board: [...board], current, winner, status, moveCount, lastMove }]);
    const nextBoard = [...board];
    nextBoard[to] = current;
    nextBoard[from] = null;
    const captured = captureTargets(nextBoard, to, current);
    captured.forEach((index) => { nextBoard[index] = null; });
    const opponent: Player = current === 'red' ? 'blue' : 'red';
    const opponentCount = nextBoard.filter((cell) => cell === opponent).length;
    const didWin = opponentCount <= 1 || !hasAnyMove(nextBoard, opponent);

    setBoard(nextBoard);
    setSelected(null);
    setLastMove(to);
    setMoveCount((value) => value + 1);
    if (didWin) {
      setWinner(current);
      setStatus(`${current === 'red' ? '红方' : '蓝方'}获胜！漂亮的一局`);
      playSfx('win');
    } else {
      setCurrent(opponent);
      setStatus(captured.length > 0
        ? `${current === 'red' ? '红方' : '蓝方'}形成活枪，吃掉 ${captured.length} 枚棋子`
        : `${opponent === 'red' ? '红方' : '蓝方'}回合，请选择棋子`);
      playSfx(captured.length > 0 ? 'capture' : 'move');
    }
  }, [board, current, lastMove, moveCount, playSfx, status, winner]);

  const handlePoint = (index: number) => {
    if (winner) return;
    const cell = board[index];
    if (cell === current) {
      setSelected((value) => value === index ? null : index);
      setStatus(`已选择${current === 'red' ? '红' : '蓝'}方棋子，请走到亮起的相邻空位`);
      playSfx('select');
      return;
    }
    if (selected !== null && validMoves.includes(index)) {
      movePiece(selected, index);
      return;
    }
    setStatus(cell ? `现在是${current === 'red' ? '红方' : '蓝方'}回合` : '该位置不能到达，请选择亮起的空位');
  };

  const undo = () => {
    const snapshot = history.at(-1);
    if (!snapshot) {
      setStatus('当前没有可以悔棋的步骤');
      return;
    }
    setBoard(snapshot.board);
    setCurrent(snapshot.current);
    setWinner(snapshot.winner);
    setStatus('已撤回上一步');
    setMoveCount(snapshot.moveCount);
    setLastMove(snapshot.lastMove);
    setSelected(null);
    setHistory((previous) => previous.slice(0, -1));
    playSfx('select');
  };

  const toggleMusic = () => {
    if (musicOn) {
      stopMusic();
      setMusicOn(false);
    } else {
      startMusic(musicTrack);
      setMusicOn(true);
    }
  };

  const chooseTrack = (track: MusicTrack) => {
    setMusicTrack(track);
    if (musicOn) startMusic(track);
  };

  return (
    <main className={`game-shell skin-${boardSkin} pieces-${pieceSkin}`}>
      <header className="topbar">
        <button className="brand" onClick={resetGame} aria-label="重新开始六子冲">
          <span className="brand-mark"><i /><i /><i /></span>
          <span><b>六子冲</b><small>LINE OF SIX</small></span>
        </button>
        <div className="top-actions">
          <button className={`icon-button ${musicOn ? 'active' : ''}`} onClick={toggleMusic} aria-label={musicOn ? '关闭音乐' : '开启音乐'}>{musicOn ? '♪' : '♩'}</button>
          <button className="icon-button" onClick={() => setRulesOpen(true)} aria-label="游戏说明">?</button>
        </div>
      </header>

      <section className="play-layout">
        <div className="play-stage">
          <div className="stage-heading">
            <div>
              <p className="eyebrow">传统民间对弈 · 第 {String(moveCount + 1).padStart(2, '0')} 手</p>
              <h1>{winner ? `${winner === 'red' ? '红方' : '蓝方'}胜出` : '双子成锋，一步制胜'}</h1>
            </div>
            <div className={`turn-pill ${current}`}><span /> {winner ? '棋局结束' : `${current === 'red' ? '红方' : '蓝方'}回合`}</div>
          </div>

          <div className="board-wrap">
            <div className="board-frame">
              <div className="board-corner tl" /><div className="board-corner tr" />
              <div className="board-corner bl" /><div className="board-corner br" />
              <div className="board" role="grid" aria-label="六子冲棋盘">
                <div className="board-lines" aria-hidden="true">
                  {Array.from({ length: ROWS }, (_, row) => <i className="h-line" key={`h-${row}`} style={{ top: `${row * 25}%` }} />)}
                  {Array.from({ length: COLS }, (_, col) => <i className="v-line" key={`v-${col}`} style={{ left: `${col * 33.333}%` }} />)}
                </div>
                {board.map((side, index) => {
                  const { row, col } = coords(index);
                  const isValid = validMoves.includes(index);
                  return (
                    <button
                      className={`point ${side ? `has-piece ${side}` : ''} ${selected === index ? 'selected' : ''} ${isValid ? 'valid' : ''} ${lastMove === index ? 'last-move' : ''}`}
                      key={index}
                      style={{ left: `${col * 33.333}%`, top: `${row * 25}%` }}
                      onClick={() => handlePoint(index)}
                      role="gridcell"
                      aria-label={side ? `${side === 'red' ? '红' : '蓝'}方棋子，第${row + 1}行第${col + 1}列` : `空棋位，第${row + 1}行第${col + 1}列`}
                    >{side && <span className="piece"><i>{pieceSkin === 'flat' ? '' : side === 'red' ? '冲' : '守'}</i></span>}</button>
                  );
                })}
              </div>
            </div>
            <div className="player-tag player-red"><span className="mini-piece red" />红方 <b>{counts.red}</b></div>
            <div className="player-tag player-blue"><span className="mini-piece blue" />蓝方 <b>{counts.blue}</b></div>
            {winner && <div className="winner-seal"><small>胜者</small><b>{winner === 'red' ? '红' : '蓝'}</b><span>再来一局</span></div>}
          </div>

          <div className="status-line" role="status"><span>✦</span>{status}</div>
          <div className="board-actions">
            <button onClick={undo} disabled={history.length === 0}>↶ 悔棋</button>
            <button onClick={resetGame}>⟳ 重新开局</button>
          </div>
        </div>

        <aside className="control-panel">
          <div className="panel-intro">
            <p className="eyebrow">本地双人模式</p>
            <h2>棋局设置</h2>
            <p>同屏轮流走子，主动形成“二打一”的活枪即可吃子。</p>
          </div>

          <div className="setting-group">
            <div className="setting-title"><span>棋盘皮肤</span><b>0{BOARD_SKINS.length}</b></div>
            <div className="skin-row four">
              {BOARD_SKINS.map((skin) => (
                <button key={skin.id} onClick={() => setBoardSkin(skin.id)} className={`skin-card ${skin.id} ${boardSkin === skin.id ? 'active' : ''}`} aria-pressed={boardSkin === skin.id}>
                  <i /><span>{skin.label}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="setting-group">
            <div className="setting-title"><span>棋子样式</span><b>0{PIECE_SKINS.length}</b></div>
            <div className="piece-options four">
              {PIECE_SKINS.map((skin) => (
                <button key={skin.id} onClick={() => setPieceSkin(skin.id)} className={`piece-choice ${pieceSkin === skin.id ? 'active' : ''}`} aria-pressed={pieceSkin === skin.id}>
                  <i className={`demo-piece ${skin.id}`} /><span>{skin.label}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="audio-settings">
            <div className="sound-row">
              <span><i>♫</i><b>背景音乐</b><small>{MUSIC_TRACKS.find((track) => track.id === musicTrack)?.label}</small></span>
              <button className={`toggle ${musicOn ? 'on' : ''}`} onClick={toggleMusic} aria-label="切换背景音乐" aria-pressed={musicOn}><i /></button>
            </div>
            <div className="track-picker" aria-label="选择背景音乐">
              {MUSIC_TRACKS.map((track) => <button key={track.id} onClick={() => chooseTrack(track.id)} className={musicTrack === track.id ? 'active' : ''}>{track.label}</button>)}
            </div>
            <div className="sound-row">
              <span><i>♬</i><b>落子音效</b><small>木音 · 吃子 · 胜利</small></span>
              <button className={`toggle ${sfxOn ? 'on' : ''}`} onClick={() => { setSfxOn((value) => !value); if (!sfxOn) tone(440, .12, .04); }} aria-label="切换落子音效" aria-pressed={sfxOn}><i /></button>
            </div>
          </div>

          <button className="primary-button" onClick={resetGame}>{winner ? '再来一局' : '开始新局'} <span>→</span></button>
          <button className="rules-link" onClick={() => setRulesOpen(true)}>查看完整规则 <span>↗</span></button>
        </aside>
      </section>

      {rulesOpen && (
        <div className="modal-backdrop" role="presentation" onMouseDown={() => setRulesOpen(false)}>
          <section className="rules-modal" role="dialog" aria-modal="true" aria-labelledby="rules-title" onMouseDown={(event) => event.stopPropagation()}>
            <button className="modal-close" onClick={() => setRulesOpen(false)} aria-label="关闭规则">×</button>
            <p className="eyebrow">HOW TO PLAY</p>
            <h2 id="rules-title">六子冲 · 活枪规则</h2>
            <ol>
              <li><b>走一步</b><span>每回合选择一枚己方棋子，沿横线或竖线移动到相邻空点，不能跳跃或斜走。</span></li>
              <li><b>二打一</b><span>本步主动形成连续的“己—己—敌”，且三子之外没有紧邻棋子，便可吃掉枪口的敌子。</span></li>
              <li><b>定胜负</b><span>把对方吃到只剩一枚，或让对方完全无路可走，即获得胜利。</span></li>
            </ol>
            <div className="rule-example"><i className="dot red" /><i className="dot red" /><i className="dot blue target" /><span>两枚己子形成枪身，吃掉枪口敌子</span></div>
            <button className="primary-button" onClick={() => setRulesOpen(false)}>明白了，开始对弈</button>
          </section>
        </div>
      )}
    </main>
  );
}
