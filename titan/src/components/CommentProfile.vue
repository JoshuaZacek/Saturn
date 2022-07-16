<template>
  <div class="container">
    <p class="commentHeader">
      Commented on
      <span
        class="postTitle"
        @click="
          $router.push({ name: 'PostWithComments', params: { id: comment.post.id } })
        "
        >{{ comment.post.title }}</span
      >
    </p>

    <div class="comment">
      <div class="profileImage"></div>

      <div class="commentCollaper"></div>

      <div class="details">
        <p>@{{ comment.user.username }}</p>

        <p>{{ timeSince }}</p>
      </div>

      <p>{{ comment.content }}</p>
    </div>

    <VoteButtons :content="comment" type="comment" />

    <button
      class="replyButton"
      @click="
        $router.push({
          name: 'PostWithComments',
          params: { id: comment.post.id, comment: comment.id },
        })
      "
    >
      <img src="/comment.svg" height="15" />
      See replies
    </button>
  </div>
</template>

<script lang="ts">
import { Options, Vue } from "vue-class-component";
import VoteButtons from "@/components/VoteButtons.vue";
import { relativeTime } from "@/relativeTime";

@Options({
  props: {
    comment: Object,
  },
  components: {
    VoteButtons,
  },
})
export default class CommentProfile extends Vue {
  comment!: Record<string, unknown>;

  get timeSince(): string {
    return relativeTime(new Date(<string>this.comment.inserted_at));
  }
}
</script>

<style scoped>
.container {
  width: 550px;
  background-color: var(--backgroundSecondary);
  padding: 15px 20px 10px;
  border-radius: 15px;
  margin-bottom: 20px;
  box-sizing: border-box;
}
.comment {
  position: relative;
  padding: 0px 0px 0px 10px;
  margin: 10px 0px 10px 10px;
}

.profileImage {
  width: 15px;
  height: 15px;
  position: absolute;
  background-color: var(--backgroundTertiary);
  border-radius: 50%;
  left: -11.5px;
}
.commentCollaper {
  width: 2px;
  background-color: var(--backgroundTertiary);
  height: calc(100% - 20px);
  position: absolute;
  left: -5px;
  top: 20px;
  border-radius: 1px;
}
.commentHeader {
  font-size: 14px;
  color: var(--textSecondary);
}
.postTitle {
  color: var(--textPrimary);
  font-weight: bold;
}
.postTitle:hover {
  text-decoration: underline;
  cursor: pointer;
}

.details {
  font-size: 14px;
  margin-bottom: 1px;
}
.details > * {
  display: inline-block;
}
.details > *:not(:last-child):after {
  content: "//";
  color: var(--textSecondary);
  margin: 0px 7px;
  display: inline-block;
  font-weight: normal;
}
.details > p {
  color: var(--textSecondary);
}
.details > p:first-child {
  color: var(--textPrimary);
  font-weight: bold;
}

.replyButton {
  padding: 5px 10px;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  margin-top: -5px;

  font-size: 15px;
  font-weight: normal;

  background-color: transparent;
  color: var(--textPrimary);

  display: inline-flex;
  justify-content: center;
  align-items: center;
}
@media (hover: hover) {
  .replyButton:hover {
    background-color: var(--backgroundTertiary);
  }
}
.replyButton > img {
  margin-right: 5px;
}

@media screen and (max-width: 590px) {
  .container {
    width: calc(100% - 40px);
  }
}
</style>
