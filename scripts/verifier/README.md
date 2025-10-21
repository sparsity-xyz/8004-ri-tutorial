
# signature verification

## install
```
pip install -r requirements.txt
```

## verify
```
# GET
python3 verify.py --agent-id=17 --url-path=/hello_world

# POST
python3 verify.py --agent-id=17 --url-path=/add_two --data='{"a": 1, "b": 2}'
```