local API_URL = "http://127.0.0.1:3000/send"
local API_KEY = "123456"

local codigos = {}
local tempos = {}

-- 🔢 gerar código
function gerarCodigo()
    return tostring(math.random(100000, 999999))
end

-- 📧 comando para enviar código
function enviarCodigo(player, cmd, email)
    if not email then
        outputChatBox("Use: /codigo [email]", player, 255, 0, 0)
        return
    end

    if tempos[player] and getTickCount() < tempos[player] then
        local restante = math.ceil((tempos[player] - getTickCount()) / 1000)
        outputChatBox("Aguarde " .. restante .. " segundos para gerar outro código.", player, 255, 0, 0)
        return
    end
    
    tempos[player] = getTickCount() + 120000 -- 2 minutos de tempo de espera

    local codigo = gerarCodigo()
    codigos[player] = codigo

    local data = toJSON({
        key = API_KEY,
        to = email,
        subject = "Seu código de verificação",
        message = "Seu código é: " .. codigo
    })
    data = string.sub(data, 2, -2) -- O MTA adiciona [ ] em volta do JSON, o Node.js não aceita isso, então nós removemos.

    fetchRemote(API_URL, {
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json"
        },
        postData = data
    },
    function(res, info)
        if info.success then
            -- Verifica se a resposta da API (que é em JSON) retornou success: true
            local responseData = fromJSON(res)
            if responseData and responseData.success then
                outputChatBox("Código enviado para o email!", player, 0, 255, 0)
            else
                local motivo = responseData and responseData.error or "desconhecido"
                outputChatBox("Erro do SendGrid! Motivo: " .. tostring(motivo), player, 255, 0, 0)
                outputDebugString("Erro da API: " .. tostring(res))
            end
        else
            outputChatBox("Falha de conexão com a API local (Status: " .. tostring(info.statusCode) .. ")", player, 255, 0, 0)
            outputDebugString("Falha fetchRemote: Status " .. tostring(info.statusCode) .. " | Res: " .. tostring(res))
        end
    end)
end
addCommandHandler("codigo", enviarCodigo)

-- ✅ verificar código
function verificarCodigo(player, cmd, codigo)
    if not codigo then
        outputChatBox("Use: /verificar [codigo]", player, 255, 0, 0)
        return
    end

    local codigoSalvo = codigos[player]

    if not codigoSalvo then
        outputChatBox("Você não pediu nenhum código! Use /codigo primeiro.", player, 255, 0, 0)
        return
    end

    if codigoSalvo == codigo then
        outputChatBox("Código correto!", player, 0, 255, 0)
        codigos[player] = nil
    else
        outputChatBox("Código inválido! (Digitado: " .. tostring(codigo) .. " | Esperado: " .. tostring(codigoSalvo) .. ")", player, 255, 0, 0)
    end
end
addCommandHandler("verificar", verificarCodigo)

-- limpar ao sair
addEventHandler("onPlayerQuit", root, function()
    codigos[source] = nil
    tempos[source] = nil
end)