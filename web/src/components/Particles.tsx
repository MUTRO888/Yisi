import { useEffect, useRef } from 'react'
import './Particles.css'

function Particles() {
    const canvasRef = useRef<HTMLCanvasElement>(null)

    useEffect(() => {
        const canvas = canvasRef.current
        if (!canvas) return

        const ctx = canvas.getContext('2d')
        if (!ctx) return

        let animationFrameId: number
        let particles: Particle[] = []

        const resizeCanvas = () => {
            canvas.width = window.innerWidth
            canvas.height = window.innerHeight
            initParticles()
        }

        class Particle {
            x: number
            y: number
            size: number
            speedX: number
            speedY: number
            opacity: number

            constructor() {
                this.x = Math.random() * (canvas?.width || 0)
                this.y = Math.random() * (canvas?.height || 0)
                this.size = Math.random() * 1.5 + 0.5
                this.speedX = Math.random() * 0.2 - 0.1
                this.speedY = Math.random() * 0.2 - 0.1
                this.opacity = Math.random() * 0.5 + 0.1
            }

            update() {
                this.x += this.speedX
                this.y += this.speedY

                if (canvas) {
                    if (this.x < 0) this.x = canvas.width
                    if (this.x > canvas.width) this.x = 0
                    if (this.y < 0) this.y = canvas.height
                    if (this.y > canvas.height) this.y = 0
                }
            }

            draw() {
                if (!ctx) return
                ctx.fillStyle = `rgba(0, 0, 0, ${this.opacity})` // Dark particles for light mode
                // In a real app we'd probably want to make this theme-aware or passed as a prop
                // But Yisi/Antigravity seems to be light-themed primarily in the screenshots
                ctx.beginPath()
                ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        const initParticles = () => {
            particles = []
            const numberOfParticles = Math.floor((canvas.width * canvas.height) / 15000)
            for (let i = 0; i < numberOfParticles; i++) {
                particles.push(new Particle())
            }
        }

        const animate = () => {
            if (!ctx || !canvas) return
            ctx.clearRect(0, 0, canvas.width, canvas.height)

            particles.forEach(particle => {
                particle.update()
                particle.draw()
            })

            animationFrameId = requestAnimationFrame(animate)
        }

        window.addEventListener('resize', resizeCanvas)
        resizeCanvas()
        animate()

        return () => {
            window.removeEventListener('resize', resizeCanvas)
            cancelAnimationFrame(animationFrameId)
        }
    }, [])

    return <canvas ref={canvasRef} className="particles-canvas" />
}

export default Particles
