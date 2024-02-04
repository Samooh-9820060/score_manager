const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.updateTournamentScores = functions.firestore
    .document("games/{gameId}")
    .onWrite(async (change, context) => {
      const gameData = change.after.exists ? change.after.data() : null;
      const tournamentId = gameData ? gameData.tournamentId : null;
      const isUpdate = change.before.exists && change.after.exists;
      const previousGameData = change.before.exists ? change.before.data() : {};

      if (!tournamentId) return;

      // Fetch tournament data
      const tournamentRef = admin.firestore().collection("tournaments").doc(tournamentId);
      const tournamentSnapshot = await tournamentRef.get();
      if (!tournamentSnapshot.exists) return;
      const tournamentData = tournamentSnapshot.data();

      const participants = tournamentData.participants || [];
      const scoresData = {};
      const winsData = {};

      if (isUpdate) {
        // Logic to adjust scores and wins if it's an update
        Object.keys(gameData.scores).forEach((participantName) => {
          const newScore = parseInt(gameData.scores[participantName], 10) || 0;
          const oldScore = parseInt(previousGameData.scores[participantName], 10) || 0;
          const scoreDifference = newScore - oldScore;
          const participantIndex = participants.findIndex((p) => p.name === participantName);

          if (participantIndex !== -1) {
            scoresData[participantIndex] = (scoresData[participantIndex] || 0) + scoreDifference;
            // Update wins
            if (previousGameData.winnerName !== gameData.winnerName) {
              if (participantName === gameData.winnerName) {
                winsData[participantIndex] = (winsData[participantIndex] || 0) + 1;
              }
              if (participantName === previousGameData.winnerName) {
                winsData[participantIndex] = (winsData[participantIndex] || 0) - 1;
              }
            }
          }
        });
      } else {
        // Logic for new game
        Object.keys(gameData.scores).forEach((participantName) => {
          const score = parseInt(gameData.scores[participantName], 10) || 0;
          const participantIndex = participants.findIndex((p) => p.name === participantName);

          if (participantIndex !== -1) {
            // Update scores
            scoresData[participantIndex] = (scoresData[participantIndex] || 0) + score;

            // Update wins
            if (participantName === gameData.winnerName) {
              winsData[participantIndex] = (winsData[participantIndex] || 0) + 1;
            }
          }
        });
      }

      // Update aggregated scores
      const scoresRef = admin.firestore().collection("tournamentScores").doc(tournamentId);
      const scoresSnapshot = await scoresRef.get();
      const existingData = scoresSnapshot.exists ? scoresSnapshot.data() : {scores: {}, wins: {}};

      // Merge existing scores and wins with new data
      Object.keys(scoresData).forEach((index) => {
        existingData.scores[index] = (existingData.scores[index] || 0) + scoresData[index];
      });

      Object.keys(winsData).forEach((index) => {
        existingData.wins[index] = (existingData.wins[index] || 0) + winsData[index];
      });

      await scoresRef.set(existingData, {merge: true});
    });
