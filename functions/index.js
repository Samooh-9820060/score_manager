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
  const month = date.getMonth() + 1;
  const day = date.getDate();
  return `${year}-${month}-${day}`;
}

exports.updateTournamentScores = functions.firestore
    .document("games/{gameId}")
    .onWrite(async (change, context) => {
      const gameData = change.after.exists ? change.after.data() : null;
      const previousGameData = change.before.exists ? change.before.data() : null;
      const tournamentId = gameData ? gameData.tournamentId : null;
      if (!tournamentId || !gameData) return;

      const newDateKey = getDailyPeriodKey(new Date(gameData.dateTime));
      const oldDateKey = previousGameData ? getDailyPeriodKey(new Date(previousGameData.dateTime)) : null;
      const dateChanged = oldDateKey && newDateKey !== oldDateKey;

      const tournamentRef = admin.firestore().collection("tournaments").doc(tournamentId);
      const tournamentSnapshot = await tournamentRef.get();
      if (!tournamentSnapshot.exists) return;
      const tournamentData = tournamentSnapshot.data();

      const tournamentScoresRef = admin.firestore().collection("pointFrequencyData").doc(tournamentId);
      const tournamentScoresSnapshot = await tournamentScoresRef.get();
      const tournamentScoresData = tournamentScoresSnapshot.exists ? tournamentScoresSnapshot.data() : {};

      tournamentScoresData[newDateKey] = tournamentScoresData[newDateKey] || {scores: {}, wins: {}};
      if (dateChanged) {
        tournamentScoresData[oldDateKey] = tournamentScoresData[oldDateKey] || {scores: {}, wins: {}};
      }

      tournamentData.participants.forEach((participant, index) => {
        const newScore = parseInt(gameData.scores[participant.name], 10) || 0;
        const previousScore = previousGameData ? parseInt(previousGameData.scores[participant.name], 10) || 0 : 0;
        const scoreDifference = newScore - previousScore;

        if (dateChanged) {
          const previousScore = previousGameData ? parseInt(previousGameData.scores[participant.name], 10) : 0;

          // Reverse the scores and wins on the old date
          tournamentScoresData[oldDateKey].scores[index] = (tournamentScoresData[oldDateKey].scores[index] || 0) - previousScore;
          if (previousGameData && previousGameData.winnerName === participant.name) {
            tournamentScoresData[oldDateKey].wins[index] = (tournamentScoresData[oldDateKey].wins[index] || 0) - 1;
          }

          // Add the current game's scores and wins to the new date
          tournamentScoresData[newDateKey].scores[index] = (tournamentScoresData[newDateKey].scores[index] || 0) + newScore;
          if (gameData.winnerName === participant.name) {
            tournamentScoresData[newDateKey].wins[index] = (tournamentScoresData[newDateKey].wins[index] || 0) + 1;
          }
        } else {
          // Update scores and wins on the new date
          tournamentScoresData[newDateKey].scores[index] = (tournamentScoresData[newDateKey].scores[index] || 0) + scoreDifference;
          if (gameData.winnerName === participant.name) {
            if (!previousGameData || previousGameData.winnerName !== participant.name) {
              tournamentScoresData[newDateKey].wins[index] = (tournamentScoresData[newDateKey].wins[index] || 0) + 1;
            }
          } else if (previousGameData && previousGameData.winnerName === participant.name) {
            tournamentScoresData[newDateKey].wins[index] = (tournamentScoresData[newDateKey].wins[index] || 0) - 1;
          }
        }
      });

      await tournamentScoresRef.set(tournamentScoresData, {merge: true});
    });
