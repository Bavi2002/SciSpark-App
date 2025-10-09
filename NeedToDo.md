
## Component 1 – Experiment Management (Teacher)
1. Teachers can create, edit, and delete experiments. <when update unable to add step>
2. Add experiment metadata: title, description, subject area, difficulty level.<Video and Image handling>
3. Add list of required materials.<DONE>
4. Add step-by-step instructions (text + image/video uploads).<media preview need to done>
5. (Novel Trend – OpenAI API): AI support for auto-generating experiment metadata and step suggestions.<Need some enhancements>
6. APIs for storing/retrieving experiments. <DONE>
7. Data storage in MongoDB (with AWS S3 for media). <AWS s3 >

## Component 2 – Student Learning & Progress Tracking
1. Students can browse and select experiments.<Need to add search>
2. Follow experiment steps with images or video demonstrations.<media>
3. (Novel Trend – TTS): Instructions can be read aloud step-by-step for accessibility and hands-free learning.<UI enhancement>
4. Mark steps as “completed.”<DONE>
5. Earn rewards/badges upon completion.<DONE>
6. Track personal progress (experiments started, completed, achievements).<DONE>
7. APIs for storing student progress & achievements.<DONE>

Component 3 – Parent Dashboard -  <Need to discuss>
1. Parents can log in and view their child’s progress.
2. See experiments completed, badges earned, and overall activity.
3. Dashboard view in the Android app (dedicated parent screen).
4. Backend APIs to fetch child’s activity and achievements.<DONE>
5. Secure role-based access (JWT) for parents.
6. (Novel Trend – TTS): Parents can listen to child’s progress reports and activity summaries.

Component 4 – AI Assistant (Student Support) - <DONE>
AI Assistant integrated as a chat/voice bot in the app (bottom-right corner).
Supports:
    1. Text input → (Novel Trend – OpenAI API) ChatGPT response.
    2. Voice input (Speech-to-Text) → ChatGPT → TTS output.
    3. Provides instant guidance when students face difficulties.
    4. Context-aware help (related to current experiment step).
    5. Backend integration with OpenAI API.

Novel Trends Used
    • TTS enhances UX by improving accessibility, reducing cognitive load, and supporting diverse users (students & parents).
    • OpenAI API enhances UX by providing personalized, intelligent, and conversational assistance for both teachers (content creation) and students (learning support).

