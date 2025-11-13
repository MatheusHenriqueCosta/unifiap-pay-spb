import os
from datetime import datetime

LOG_PATH = '/var/logs/api/instrucoes.log'


def run_auditoria():
    if not os.path.exists(LOG_PATH):
        print('Nenhuma instrucao encontrada.')
        return 0

    with open(LOG_PATH, 'r', encoding='utf-8') as f:
        lines = [l.strip() for l in f if l.strip()]

    aguardando = []
    for l in lines:
        parts = l.split('|')
        if len(parts) >= 4:
            status = parts[3]
            if status == 'AGUARDANDO_LIQUIDACAO':
                aguardando.append(parts)

    if not aguardando:
        print('Sem transações aguardando liquidação.')
        return 0

    with open(LOG_PATH, 'a', encoding='utf-8') as f:
        for parts in aguardando:
            txid = parts[1]
            amount = parts[2]
            new_line = f"{datetime.utcnow().isoformat()}|{txid}|{amount}|LIQUIDADO|auditoria|{parts[5] if len(parts)>5 else 'unknown'}\n"
            f.write(new_line)
            print('Liquidado', txid)

    return len(aguardando)


if __name__ == '__main__':
    count = run_auditoria()
    print(f'Processadas: {count}')
