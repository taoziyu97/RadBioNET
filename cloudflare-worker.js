// Cloudflare Worker — proxy the Hong Kong RadBioNet Shiny app.
// Bind this Worker to radbionet.com/* so the public URL stays on the
// main domain while HTTP and WebSocket traffic use the stable HK origin.

const SHINY_ORIGIN = 'https://hk-app.radbionet.com'
const PUBLIC_ORIGIN = 'https://radbionet.com'

async function handleRequest(request) {
  const url = new URL(request.url)
  const originUrl = SHINY_ORIGIN + url.pathname + url.search

  const proxyHeaders = new Headers(request.headers)
  proxyHeaders.set('Host', 'hk-app.radbionet.com')
  proxyHeaders.set('Origin', SHINY_ORIGIN)

  if (request.headers.get('upgrade')?.toLowerCase() === 'websocket') {
    return fetch(new Request(originUrl, {
      method: request.method,
      headers: proxyHeaders
    }))
  }

  const response = await fetch(new Request(originUrl, {
    method: request.method,
    headers: proxyHeaders,
    body: ['GET', 'HEAD'].includes(request.method) ? null : request.body,
    redirect: 'follow'
  }))

  const responseHeaders = new Headers(response.headers)
  const location = responseHeaders.get('Location')
  if (location) {
    responseHeaders.set('Location', location.replace(SHINY_ORIGIN, PUBLIC_ORIGIN))
  }
  responseHeaders.set('Cache-Control', 'no-store')

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: responseHeaders
  })
}

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})
