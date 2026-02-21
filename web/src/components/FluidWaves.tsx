import { useRef, useEffect, useCallback } from 'react'

interface WaveLine {
  baseY: number
  amplitude: number
  frequency: number
  phase: number
  speed: number
  harmAmp: number
  harmFreq: number
  harmPhase: number
  hue: number
  lightness: number
  alpha: number
}

const LINE_COUNT = 36
const LINE_COUNT_MOBILE = 20
const MOUSE_RADIUS_SQ = 200 * 200
const MOUSE_FORCE = 50
const BG_COLOR = '#fafafa'
const BAND_CENTER = 0.5
const BAND_HALF = 0.2
const FADE_EDGE = 0.7

function createLines(height: number): WaveLine[] {
  const mobile = window.innerWidth <= 768
  const count = mobile ? LINE_COUNT_MOBILE : LINE_COUNT
  const lines: WaveLine[] = []

  const bandTop = (BAND_CENTER - BAND_HALF) * height
  const bandHeight = BAND_HALF * 2 * height

  for (let i = 0; i < count; i++) {
    const ratio = i / (count - 1)
    const baseY = bandTop + bandHeight * ratio + (Math.random() - 0.5) * bandHeight * 0.08

    const amplitude = 15 + Math.random() * 35
    const frequency = 0.0012 + Math.random() * 0.0018
    const phase = Math.random() * Math.PI * 2
    const speed = 0.004 + Math.random() * 0.004

    const distFromCenter = Math.abs(ratio - 0.5) * 2
    const edgeFade = distFromCenter < FADE_EDGE ? 1
      : 1 - (distFromCenter - FADE_EDGE) / (1 - FADE_EDGE)

    const hue = 243 + Math.random() * 20
    const lightness = 55 + (1 - ratio) * 15
    const alpha = (0.35 + ratio * 0.35) * Math.max(0, edgeFade)

    lines.push({
      baseY, amplitude, frequency, phase, speed,
      harmAmp: amplitude * (0.15 + Math.random() * 0.3),
      harmFreq: frequency * (2.5 + Math.random() * 2),
      harmPhase: Math.random() * Math.PI * 2,
      hue, lightness, alpha,
    })
  }

  return lines
}

function FluidWaves() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const linesRef = useRef<WaveLine[]>([])
  const mouseRef = useRef({ x: -1000, y: -1000 })
  const animIdRef = useRef(0)
  const activeRef = useRef(true)
  const timeRef = useRef(0)
  const sizeRef = useRef({ w: 0, h: 0 })

  const draw = useCallback(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const dpr = window.devicePixelRatio || 1
    const w = sizeRef.current.w
    const h = sizeRef.current.h

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    ctx.fillStyle = BG_COLOR
    ctx.fillRect(0, 0, w, h)

    const lines = linesRef.current
    const mx = mouseRef.current.x
    const my = mouseRef.current.y
    const t = timeRef.current
    timeRef.current += 1

    const step = 10

    for (let i = 0; i < lines.length; i++) {
      const ln = lines[i]
      const tSpeed = t * ln.speed
      const tHarm = t * ln.speed * 0.7

      ctx.beginPath()
      ctx.strokeStyle = `hsla(${ln.hue}, 38%, ${ln.lightness}%, ${ln.alpha})`
      ctx.lineWidth = 1

      let px = 0
      let py = 0

      for (let x = 0; x <= w; x += step) {
        let y = ln.baseY
          + Math.sin(x * ln.frequency + ln.phase + tSpeed) * ln.amplitude
          + Math.sin(x * ln.harmFreq + ln.harmPhase + tHarm) * ln.harmAmp

        const dx = x - mx
        const dy = y - my
        const distSq = dx * dx + dy * dy
        if (distSq < MOUSE_RADIUS_SQ) {
          const ratio = 1 - Math.sqrt(distSq) / 200
          y += (dy > 0 ? 1 : -1) * ratio * ratio * MOUSE_FORCE
        }

        if (x === 0) {
          ctx.moveTo(x, y)
        } else {
          ctx.quadraticCurveTo(px, py, (px + x) * 0.5, (py + y) * 0.5)
        }
        px = x
        py = y
      }

      ctx.stroke()
    }
  }, [])

  const animate = useCallback(() => {
    if (!activeRef.current) return
    draw()
    animIdRef.current = requestAnimationFrame(animate)
  }, [draw])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const resize = () => {
      const dpr = window.devicePixelRatio || 1
      const rect = canvas.parentElement!.getBoundingClientRect()
      const w = rect.width
      const h = rect.height
      canvas.width = w * dpr
      canvas.height = h * dpr
      canvas.style.width = `${w}px`
      canvas.style.height = `${h}px`
      sizeRef.current = { w, h }
      linesRef.current = createLines(h)
    }

    const ro = new ResizeObserver(resize)
    ro.observe(canvas.parentElement!)
    resize()

    const onMove = (e: MouseEvent) => {
      const rect = canvas.getBoundingClientRect()
      mouseRef.current = { x: e.clientX - rect.left, y: e.clientY - rect.top }
    }
    const onLeave = () => {
      mouseRef.current = { x: -1000, y: -1000 }
    }

    canvas.addEventListener('mousemove', onMove)
    canvas.addEventListener('mouseleave', onLeave)

    return () => {
      ro.disconnect()
      canvas.removeEventListener('mousemove', onMove)
      canvas.removeEventListener('mouseleave', onLeave)
    }
  }, [])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const observer = new IntersectionObserver(
      ([entry]) => {
        activeRef.current = entry.isIntersecting
        if (entry.isIntersecting) {
          animIdRef.current = requestAnimationFrame(animate)
        } else {
          cancelAnimationFrame(animIdRef.current)
        }
      },
      { threshold: 0.05 },
    )
    observer.observe(canvas)

    activeRef.current = true
    animIdRef.current = requestAnimationFrame(animate)

    return () => {
      observer.disconnect()
      cancelAnimationFrame(animIdRef.current)
    }
  }, [animate])

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: 'absolute',
        inset: 0,
        width: '100%',
        height: '100%',
        pointerEvents: 'auto',
      }}
    />
  )
}

export default FluidWaves
