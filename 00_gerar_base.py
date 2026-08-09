"""
Gera base sintética (mas realista) de uma adquirente de pagamentos (maquininha de cartão).
Calibrada com padrões públicos de mercado (MDR por modalidade, taxa de aprovação, chargeback rate).
Saída: 03_dados/lojistas.csv, maquininhas.csv, transacoes.csv
"""
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import random

rng = np.random.default_rng(42)
random.seed(42)

N_LOJISTAS = 3000
N_TRANSACOES = 60000

UFS_REGIAO = {
    "SP": "Sudeste", "RJ": "Sudeste", "MG": "Sudeste", "ES": "Sudeste",
    "PR": "Sul", "SC": "Sul", "RS": "Sul",
    "BA": "Nordeste", "PE": "Nordeste", "CE": "Nordeste", "MA": "Nordeste", "PB": "Nordeste",
    "GO": "Centro-Oeste", "MT": "Centro-Oeste", "MS": "Centro-Oeste", "DF": "Centro-Oeste",
    "PA": "Norte", "AM": "Norte", "RO": "Norte",
}
# pesos aproximados de concentração de lojistas por UF (SP/RJ/MG puxam mais)
UF_PESOS = {
    "SP": 0.26, "RJ": 0.10, "MG": 0.09, "ES": 0.02,
    "PR": 0.08, "SC": 0.06, "RS": 0.07,
    "BA": 0.06, "PE": 0.04, "CE": 0.04, "MA": 0.02, "PB": 0.02,
    "GO": 0.04, "MT": 0.02, "MS": 0.02, "DF": 0.03,
    "PA": 0.02, "AM": 0.01, "RO": 0.01,
}
ufs = list(UF_PESOS.keys())
pesos_uf = np.array(list(UF_PESOS.values()))
pesos_uf = pesos_uf / pesos_uf.sum()

CIDADES = {
    "SP": ["São Paulo", "Campinas", "Santos", "Ribeirão Preto"],
    "RJ": ["Rio de Janeiro", "Niterói", "Duque de Caxias"],
    "MG": ["Belo Horizonte", "Uberlândia", "Juiz de Fora"],
    "ES": ["Vitória", "Vila Velha"],
    "PR": ["Curitiba", "Londrina", "Maringá"],
    "SC": ["Florianópolis", "Joinville", "Blumenau"],
    "RS": ["Porto Alegre", "Caxias do Sul"],
    "BA": ["Salvador", "Feira de Santana"],
    "PE": ["Recife", "Olinda"],
    "CE": ["Fortaleza", "Juazeiro do Norte"],
    "MA": ["São Luís"],
    "PB": ["João Pessoa"],
    "GO": ["Goiânia", "Anápolis"],
    "MT": ["Cuiabá"],
    "MS": ["Campo Grande"],
    "DF": ["Brasília"],
    "PA": ["Belém"],
    "AM": ["Manaus"],
    "RO": ["Porto Velho"],
}

SEGMENTOS = ["Varejo", "Alimentação", "Serviços", "Saúde", "Moda e Beleza", "Educação", "Outros"]
PESOS_SEGMENTO = [0.28, 0.24, 0.18, 0.08, 0.12, 0.05, 0.05]

PORTES = ["MEI", "Pequena", "Média", "Grande"]
PESOS_PORTE = [0.58, 0.27, 0.12, 0.03]

PLANOS = ["Standard", "Premium", "Enterprise"]
PESOS_PLANO = [0.70, 0.24, 0.06]

PREFIXOS_NOME = ["Casa", "Empório", "Loja", "Studio", "Espaço", "Center", "Point", "Mercadinho",
                 "Boutique", "Ateliê", "Oficina", "Clínica", "Salão", "Restaurante", "Bar", "Padaria"]
SUFIXOS_NOME = ["Bella", "Central", "Popular", "Express", "Prime", "Real", "Nova Era", "Familia",
                "do Bairro", "São José", "Bom Preço", "Estrela", "Horizonte", "Aurora", "Vitória"]

def gerar_nome_fantasia(i):
    return f"{random.choice(PREFIXOS_NOME)} {random.choice(SUFIXOS_NOME)} {i}"

# ---------------------------------------------------------------------------
# 1) LOJISTAS
# ---------------------------------------------------------------------------
lojistas = []
data_inicio_cadastro = datetime(2021, 1, 1)
data_fim_cadastro = datetime(2024, 10, 31)
dias_range = (data_fim_cadastro - data_inicio_cadastro).days

for i in range(1, N_LOJISTAS + 1):
    uf = rng.choice(ufs, p=pesos_uf)
    cidade = random.choice(CIDADES[uf])
    regiao = UFS_REGIAO[uf]
    segmento = rng.choice(SEGMENTOS, p=PESOS_SEGMENTO)
    porte = rng.choice(PORTES, p=PESOS_PORTE)
    plano = rng.choice(PLANOS, p=PESOS_PLANO)
    data_cadastro = data_inicio_cadastro + timedelta(days=int(rng.integers(0, dias_range)))
    lojistas.append({
        "lojista_id": i,
        "nome_fantasia": gerar_nome_fantasia(i),
        "segmento": segmento,
        "porte": porte,
        "plano_taxa": plano,
        "uf": uf,
        "cidade": cidade,
        "regiao": regiao,
        "data_cadastro": data_cadastro.strftime("%Y-%m-%d"),
    })

df_lojistas = pd.DataFrame(lojistas)

# ---------------------------------------------------------------------------
# 2) MAQUININHAS (1 a 3 por lojista, mais para porte maior)
# ---------------------------------------------------------------------------
MODELOS = ["Modelo Chip Básico", "Modelo Pro c/ Impressora", "Modelo Smart Android"]
PESOS_MODELO = [0.45, 0.35, 0.20]

maquininhas = []
maq_id = 1
qtd_por_porte = {"MEI": (1, 1), "Pequena": (1, 2), "Média": (1, 3), "Grande": (2, 5)}

for lj in lojistas:
    minq, maxq = qtd_por_porte[lj["porte"]]
    qtd = int(rng.integers(minq, maxq + 1))
    for _ in range(qtd):
        modelo = rng.choice(MODELOS, p=PESOS_MODELO)
        data_cad = datetime.strptime(lj["data_cadastro"], "%Y-%m-%d")
        data_ativ = data_cad + timedelta(days=int(rng.integers(0, 15)))
        status = rng.choice(["Ativa", "Ativa", "Ativa", "Ativa", "Inativa", "Bloqueada"])
        maquininhas.append({
            "maquininha_id": maq_id,
            "lojista_id": lj["lojista_id"],
            "modelo": modelo,
            "data_ativacao": data_ativ.strftime("%Y-%m-%d"),
            "status": status,
        })
        maq_id += 1

df_maquininhas = pd.DataFrame(maquininhas)

# só maquininhas ativas recebem transações (peso maior pra ativas)
maq_ativas = df_maquininhas[df_maquininhas["status"] == "Ativa"].copy()
maq_por_lojista = maq_ativas.groupby("lojista_id")["maquininha_id"].apply(list).to_dict()
lojistas_com_maquina = list(maq_por_lojista.keys())

# ---------------------------------------------------------------------------
# 3) TRANSACOES (ano de 2024)
# ---------------------------------------------------------------------------
BANDEIRAS = ["Visa", "Mastercard", "Elo", "Amex", "Outras"]
PESOS_BANDEIRA = [0.38, 0.35, 0.18, 0.05, 0.04]

MODALIDADES = ["Débito", "Crédito à Vista", "Crédito Parcelado"]
PESOS_MODALIDADE = [0.40, 0.33, 0.27]

# MDR base por modalidade (referência de mercado: débito mais barato, parcelado mais caro)
MDR_BASE = {"Débito": (1.10, 1.60), "Crédito à Vista": (2.50, 3.20), "Crédito Parcelado": (3.30, 4.80)}

# volume de transações não é uniforme por lojista: porte maior transaciona mais.
# gera pesos de "atividade" por lojista
peso_porte_ativ = {"MEI": 1.0, "Pequena": 2.5, "Média": 6.0, "Grande": 15.0}
pesos_lojista = np.array([peso_porte_ativ[lj["porte"]] for lj in lojistas if lj["lojista_id"] in lojistas_com_maquina])
pesos_lojista = pesos_lojista / pesos_lojista.sum()

data_inicio_transacao = datetime(2024, 1, 1)
data_fim_transacao = datetime(2024, 12, 31, 23, 59, 59)
dias_transacao_range = (data_fim_transacao - data_inicio_transacao).days

# sazonalidade mensal (pico em novembro/dezembro por Black Friday/Natal)
peso_mes = {1: 0.75, 2: 0.72, 3: 0.78, 4: 0.80, 5: 0.85, 6: 0.85,
            7: 0.88, 8: 0.90, 9: 0.92, 10: 1.05, 11: 1.35, 12: 1.55}
total_peso_mes = sum(peso_mes.values())
n_por_mes = {m: int(round(N_TRANSACOES * p / total_peso_mes)) for m, p in peso_mes.items()}
# ajuste de arredondamento
diff = N_TRANSACOES - sum(n_por_mes.values())
n_por_mes[12] += diff

MOTIVOS_NEGADA = ["Saldo/limite insuficiente", "Cartão bloqueado", "Suspeita de fraude",
                   "Erro de comunicação", "Cartão expirado", "Senha incorreta"]
MOTIVOS_CHARGEBACK = ["Contestação do titular", "Transação não reconhecida", "Produto não entregue",
                       "Duplicidade de cobrança", "Fraude confirmada"]

transacoes = []
tid = 1

for mes, n_mes in n_por_mes.items():
    dias_no_mes = 29 if mes == 2 else (30 if mes in (4, 6, 9, 11) else 31)
    lojista_ids_amostra = rng.choice(
        [lj_id for lj_id in lojistas_com_maquina], size=n_mes, p=pesos_lojista
    )
    for lj_id in lojista_ids_amostra:
        maquinas = maq_por_lojista[lj_id]
        maq_id_sel = random.choice(maquinas)
        lojista_row = df_lojistas.loc[df_lojistas["lojista_id"] == lj_id].iloc[0]

        dia = int(rng.integers(1, dias_no_mes + 1))
        hora = int(rng.integers(7, 23))
        minuto = int(rng.integers(0, 60))
        segundo = int(rng.integers(0, 60))
        data_transacao = datetime(2024, mes, dia, hora, minuto, segundo)

        modalidade = rng.choice(MODALIDADES, p=PESOS_MODALIDADE)
        bandeira = rng.choice(BANDEIRAS, p=PESOS_BANDEIRA)

        if modalidade == "Crédito Parcelado":
            parcelas = int(rng.choice([2, 3, 4, 5, 6, 8, 10, 12],
                                       p=[0.28, 0.20, 0.14, 0.10, 0.10, 0.08, 0.06, 0.04]))
        else:
            parcelas = 1

        # valor bruto: lognormal, porte maior transaciona valores maiores em média
        porte = lojista_row["porte"]
        mu_valor = {"MEI": 3.8, "Pequena": 4.3, "Média": 4.8, "Grande": 5.4}[porte]
        valor_bruto = float(np.round(rng.lognormal(mean=mu_valor, sigma=0.65), 2))
        valor_bruto = max(9.90, min(valor_bruto, 15000.00))

        mdr_min, mdr_max = MDR_BASE[modalidade]
        taxa_mdr_pct = float(np.round(rng.uniform(mdr_min, mdr_max) + (parcelas - 1) * 0.08, 2))
        valor_taxa = float(np.round(valor_bruto * taxa_mdr_pct / 100, 2))
        valor_liquido = float(np.round(valor_bruto - valor_taxa, 2))

        # status: aprovação ~91%, negada ~7%, estorno/chargeback ~2%
        status_roll = rng.random()
        if status_roll < 0.91:
            status = "Aprovada"
            motivo = None
        elif status_roll < 0.98:
            status = "Negada"
            motivo = random.choice(MOTIVOS_NEGADA)
        else:
            status = "Chargeback"
            motivo = random.choice(MOTIVOS_CHARGEBACK)

        # prazo de recebimento e antecipação (só p/ aprovadas, crédito)
        antecipada = False
        if status == "Aprovada":
            if modalidade == "Débito":
                prazo_recebimento_dias = 1
            else:
                prazo_recebimento_dias = 30
                if rng.random() < 0.18:
                    antecipada = True
                    prazo_recebimento_dias = 1
        else:
            prazo_recebimento_dias = None

        transacoes.append({
            "transacao_id": tid,
            "lojista_id": int(lj_id),
            "maquininha_id": int(maq_id_sel),
            "data_transacao": data_transacao.strftime("%Y-%m-%d %H:%M:%S"),
            "bandeira": bandeira,
            "modalidade": modalidade,
            "parcelas": parcelas,
            "valor_bruto": valor_bruto if status != "Negada" else valor_bruto,
            "taxa_mdr_pct": taxa_mdr_pct,
            "valor_taxa": valor_taxa if status == "Aprovada" else 0.0,
            "valor_liquido": valor_liquido if status == "Aprovada" else 0.0,
            "status": status,
            "motivo": motivo,
            "antecipada": antecipada,
            "prazo_recebimento_dias": prazo_recebimento_dias,
        })
        tid += 1

df_transacoes = pd.DataFrame(transacoes)
df_transacoes = df_transacoes.sort_values("data_transacao").reset_index(drop=True)
df_transacoes["transacao_id"] = range(1, len(df_transacoes) + 1)
df_transacoes["prazo_recebimento_dias"] = df_transacoes["prazo_recebimento_dias"].astype("Int64")
df_transacoes["antecipada"] = df_transacoes["antecipada"].map({True: "t", False: "f"})

# ---------------------------------------------------------------------------
# Salvar CSVs (delimitador ; como padrão do portfólio)
# ---------------------------------------------------------------------------
out = "/sessions/awesome-determined-cori/mnt/outputs/projeto-adquirencia-pagamentos/03_dados"
df_lojistas.to_csv(f"{out}/lojistas.csv", sep=";", index=False, encoding="utf-8")
df_maquininhas.to_csv(f"{out}/maquininhas.csv", sep=";", index=False, encoding="utf-8")
df_transacoes.to_csv(f"{out}/transacoes.csv", sep=";", index=False, encoding="utf-8")

print("lojistas:", len(df_lojistas))
print("maquininhas:", len(df_maquininhas))
print("transacoes:", len(df_transacoes))
print(df_transacoes["status"].value_counts())
print(df_transacoes.groupby("modalidade")["taxa_mdr_pct"].mean())
