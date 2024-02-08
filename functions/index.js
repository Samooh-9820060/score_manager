const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Gets the period key for a daily frequency.
 * @param {Date} date - The date for the period.
 * @return {string} The period key in YYYY-MM-DD format.
 */
function getDailyPeriodKey(date) {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, "0");
  const day = date.getDate().toString().padStart(2, "0");
  return `${year}-${month}-${day}`;
}

exports.updateTournamentScores = functions.firestore
    .document("games/{gameId}")
    .onWrite(async (change, context) => {
      const gameData = change.after.exists ? change.after.data() : null;
      const previousGameData = change.before.exists ? change.before.data() : null;
      const tournamentId = gameData ? gameData.tournamentId : null;
      if (!tournamentId || !gameData) return;

      console.log("Game data:", gameData);
      console.log("Previous game data:", previousGameData);

      const newDateKey = getDailyPeriodKey(new Date(gameData.dateTime));
      const oldDateKey = previousGameData ? getDailyPeriodKey(new Date(previousGameData.dateTime)) : null;
      const dateChanged = oldDateKey && newDateKey !== oldDateKey;

      console.log("New Date key:", newDateKey);
      console.log("Old Date key:", oldDateKey);

      const tournamentRef = admin.firestore().collection("tournaments").doc(tournamentId);
      const tournamentSnapshot = await tournamentRef.get();

      console.log("Getting Tournament Data");
      if (!tournamentSnapshot.exists) return;
      const tournamentData = tournamentSnapshot.data();

      console.log("Tournament Data:", tournamentData);

      const tournamentScoresRef = admin.firestore().collection("pointFrequencyData").doc(tournamentId);
      const tournamentScoresSnapshot = await tournamentScoresRef.get();
      const tournamentScoresData = tournamentScoresSnapshot.exists ? tournamentScoresSnapshot.data() : {};

      console.log("Tournament Scores Data:", tournamentScoresData);

      tournamentScoresData[newDateKey] = tournamentScoresData[newDateKey] || {scores: {}, wins: {}};
      if (dateChanged) {
        tournamentScoresData[oldDateKey] = tournamentScoresData[oldDateKey] || {scores: {}, wins: {}};
      }

      console.log("Getting into loop");
      console.log(tournamentData.participants);

      tournamentData.participants.forEach((participant, index) => {
        console.log(`Processing participant ${participant.name} at index ${index}`);

        const newScore = parseInt(gameData.scores[index], 10) || 0;
        const previousScore = previousGameData ? parseInt(previousGameData.scores[index], 10) || 0 : 0;
        const scoreDifference = newScore - previousScore;

        console.log("New score:", newScore);
        console.log("Previous score:", previousScore);


        if (dateChanged) {
          const previousScore = previousGameData ? parseInt(previousGameData.scores[index], 10) : 0;

          // Reverse the scores and wins on the old date
          tournamentScoresData[oldDateKey].scores[index] = (tournamentScoresData[oldDateKey].scores[index] || 0) - previousScore;
          if (previousGameData && previousGameData.winnerIndex === index) {
            tournamentScoresData[oldDateKey].wins[index] = (tournamentScoresData[oldDateKey].wins[index] || 0) - 1;
          }

          // Add the current game's scores and wins to the new date
          tournamentScoresData[newDateKey].scores[index] = (tournamentScoresData[newDateKey].scores[index] || 0) + newScore;
          if (gameData.winnerIndex === index) {
            tournamentScoresData[newDateKey].wins[index] = (tournamentScoresData[newDateKey].wins[index] || 0) + 1;
          }
        } else {
          // Update scores and wins on the new date
          tournamentScoresData[newDateKey].scores[index] = (tournamentScoresData[newDateKey].scores[index] || 0) + scoreDifference;
          if (gameData.winnerIndex === index) {
            if (!previousGameData || previousGameData.winnerIndex !== index) {
              tournamentScoresData[newDateKey].wins[index] = (tournamentScoresData[newDateKey].wins[index] || 0) + 1;
            }
          } else if (previousGameData && previousGameData.winnerIndex === index) {
            tournamentScoresData[newDateKey].wins[index] = (tournamentScoresData[newDateKey].wins[index] || 0) - 1;
          }
        }
      });

      console.log("Out of loop");
      await tournamentScoresRef.set(tournamentScoresData, {merge: true});
    });

exports.handleGameDeletion = functions.firestore
    .document("games/{gameId}")
    .onDelete(async (snapshot, context) => {
      const deletedGameData = snapshot.data();
      const tournamentId = deletedGameData.tournamentId;
      if (!tournamentId) return;

      const dateKey = getDailyPeriodKey(new Date(deletedGameData.dateTime));

      const tournamentRef = admin.firestore().collection("tournaments").doc(tournamentId);
      const tournamentSnapshot = await tournamentRef.get();
      if (!tournamentSnapshot.exists) return;
      const tournamentData = tournamentSnapshot.data();

      const tournamentScoresRef = admin.firestore().collection("pointFrequencyData").doc(tournamentId);
      const tournamentScoresSnapshot = await tournamentScoresRef.get();
      const tournamentScoresData = tournamentScoresSnapshot.exists ? tournamentScoresSnapshot.data() : {};

      if (tournamentScoresData[dateKey]) {
        tournamentData.participants.forEach((participant, index) => {
          const previousScore = parseInt(deletedGameData.scores[index], 10) || 0;
          tournamentScoresData[dateKey].scores[index] = Math.max(0, (tournamentScoresData[dateKey].scores[index] || 0) - previousScore);
          if (deletedGameData.winnerIndex === index) {
            tournamentScoresData[dateKey].wins[index] = Math.max(0, (tournamentScoresData[dateKey].wins[index] || 0) - 1);
          }
        });
      }

      await tournamentScoresRef.set(tournamentScoresData, {merge: true});
    });
