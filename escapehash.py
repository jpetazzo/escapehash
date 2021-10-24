#!/usr/bin/env python

import hashlib
import json
import os
import random
import yaml

from flask import Flask, request, Response
from werkzeug.exceptions import NotFound, NotAcceptable, UnsupportedMediaType


secret = os.environ.get("SECRET")
challenges = yaml.safe_load(open("challenges.yaml"))


def sha256(i):
    return hashlib.sha256(str(i).encode("ascii")).hexdigest()


def create_single_hash(team_name, challenge_name, challenge_index, difficulty):
    low = 10**(difficulty-1)
    high = 10**difficulty
    seed = f"{secret}.{team_name}.{challenge_name}.{challenge_index}"
    random.seed(seed)
    solution = random.randint(low, high)
    return (sha256(f"{team_name}.{solution}\n"), solution)


def get_challenge_data(team_name, challenge_name):
    data = []
    challenge = [c for c in challenges if c["name"]==challenge_name]
    if len(challenge)==0:
        raise NotFound
    challenge = challenge[0]
    for index in range(challenge["count"]):
        data.append(create_single_hash(team_name, challenge_name, index, challenge["difficulty"]))
    return data


app = Flask(__name__)


@app.route("/v1/challenges")
def get_challenges():
    return Response(json.dumps(challenges), content_type="application/json")


@app.route("/v1/team/<string:team_name>/challenge/<string:challenge_name>.<string:json_or_txt>")
def get_challenge_for_team(team_name, challenge_name, json_or_txt):
    if json_or_txt not in set(("json", "txt")):
        raise NotFound
    data = get_challenge_data(team_name, challenge_name)
    hashes = [ sha for (sha, solution) in data ]
    if json_or_txt=="txt":
        return Response("".join(h+"\n" for h in hashes), content_type="text/plain")
    if json_or_txt=="json":
        return Response(json.dumps(hashes), content_type="application/json")


@app.route("/v1/team/<string:team_name>/challenge/<string:challenge_name>", methods=["POST"])
def check_challenges_for_team(team_name, challenge_name):
    if request.content_type != "text/plain":
        raise UnsupportedMediaType
    data = get_challenge_data(team_name, challenge_name)
    solution = "".join(str(solution) for (sha, solution) in data)
    if solution==request.data.strip().decode("ascii"):
        return Response("Well done!\n", content_type="text/plain")
    else:
        raise NotAcceptable


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
