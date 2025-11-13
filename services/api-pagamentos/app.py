from flask import Flask, request, jsonify
import os
from datetime import datetime

app = Flask(__name__)

LOG_PATH = '/var/logs/api/instrucoes.log'

def ensure_log_dir():
    dirpath = os.path.dirname(LOG_PATH)
    try:
        os.makedirs(dirpath, exist_ok=True)
    except Exception:
        pass


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})


@app.route('/pix', methods=['POST'])
def create_pix():
    try:
        # accept JSON even when Content-Type header is missing (convenient for curl -d calls)
        data = request.get_json(force=True)
    except Exception:
        return jsonify({"error": "invalid json payload"}), 400
    txid = data.get('txid') or f"tx-{int(datetime.utcnow().timestamp())}"
    amount = float(data.get('amount', 0))
    origin = data.get('from', 'unifiap')
    destination = data.get('to', 'dest')

    reserva = float(os.environ.get('RESERVA_BANCARIA_SALDO', '0'))

    if amount <= 0:
        return jsonify({'error': 'amount must be > 0'}), 400

    if amount <= reserva:
        ensure_log_dir()
        line = f"{datetime.utcnow().isoformat()}|{txid}|{amount:.2f}|AGUARDANDO_LIQUIDACAO|{origin}|{destination}\n"
        with open(LOG_PATH, 'a', encoding='utf-8') as f:
            f.write(line)
        return jsonify({'txid': txid, 'status': 'AGUARDANDO_LIQUIDACAO'}), 201
    else:
        return jsonify({'error': 'SALDO_INSUFICIENTE', 'reserva': reserva}), 402


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
