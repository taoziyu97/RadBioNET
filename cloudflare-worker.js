// Cloudflare Worker — proxy RadBioNet Shiny App with WebSocket support
// Route: app.radbionet.com/RadBioNET/* → shinyapps.io/RadBioNET/*

const SHINY_ORIGIN = 'https://2cd863-taoziyu97.shinyapps.io'

async function handleRequest(request) {
  const url = new URL(request.url)
  const originUrl = SHINY_ORIGIN + url.pathname + url.search

  // Forward request with correct Host header
  const proxyHeaders = new Headers(request.headers)
  proxyHeaders.set('Host', '2cd863-taoziyu97.shinyapps.io')

  // Handle WebSocket upgrades
  if (request.headers.get('upgrade')?.toLowerCase() === 'websocket') {
    return fetch(new Request(originUrl, {
      method: request.method,
      headers: proxyHeaders
    }))
  }

  // Normal HTTP request
  const response = await fetch(new Request(originUrl, {
    method: request.method,
    headers: proxyHeaders,
    body: ['GET', 'HEAD'].includes(request.method) ? null : request.body,
    redirect: 'follow'
  }))

  return response
}

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})
